#!/bin/sh

# Check if required environment variables are set
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo "Error: Required parameters are not set"
    echo "Usage: $0 <ENV> <ACCESS_KEY> <DOMAIN_NAME>"
    echo "Example: $0 'your_env' 'your_access_key' 'your_domain.com'"
    exit 1
fi

ENV_KEY=$1
ACCESS_KEY=$2
DOMAIN_NAME=$3

# Generate authorization header
AUTHORIZATION_BASIC=$(echo -n "$ENV_KEY:$ACCESS_KEY" | tr -d '\n ' | base64 -w 0)
echo "AUTHORIZATION_BASIC: $AUTHORIZATION_BASIC"

# Generate a private key
openssl genrsa -out private_key.pem 3072

# Generate a public key from the private key (suppressing output)
openssl rsa -in private_key.pem -pubout -out public_key.pem > /dev/null 2>&1

# Generate a self-signed certificate
openssl req -new -x509 -key private_key.pem -out cert.pem \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=${DOMAIN_NAME}"

# Create a temporary file for the JSON data
JSON_DATA=$(cat <<EOF
{
  "certificate": {
    "pem": $(jq -Rs . < cert.pem),
    "private_key": $(jq -Rs . < private_key.pem)
  }
}
EOF
)

# Make the request but do not print anything
# Add -s flag to curl to suppress progress and error messages
curl -s --request POST \
    --url https://core.spreedly.com/v1/certificates \
    --header 'accept: application/json' \
    --header "authorization: Basic ${AUTHORIZATION_BASIC}" \
    --header 'content-type: application/json' \
    --data "$JSON_DATA" | jq -r '.certificate.token' > certificate_token.txt

nonce=$(uuidgen)
certificateToken=$(cat certificate_token.txt)
timestamp=$(date +%s)

# Generate a signature using the private key
echo "$nonce$timestamp$certificateToken" > signatureData.txt
PRIVATE_KEY_RAW=$(jq -Rs . < private_key.pem)
signature=$(echo -n "${nonce}${timestamp}${certificateToken}" | \
  openssl dgst -sha256 -hmac "$PRIVATE_KEY_RAW" -binary | \
  base64 -w 0)

echo "--------------------------------"
echo "NONCE (randomly generated): $nonce"
echo "TIMESTAMP: $timestamp"
echo "CERTIFICATE_TOKEN: $certificateToken"
echo "--------------------------------"
echo "SERVER_GENERATED_HMAC (OpenSSL): $signature" | tr -d '\n' | cat


RUBY_CODE=$(cat <<EOF
require 'openssl'
require 'base64'
digest = OpenSSL::Digest.new('sha256')
hmac_signature = OpenSSL::HMAC.digest(digest, ENV['PRIVATE_KEY'], ENV['SIGNATURE_DATA'])
puts "SERVER_GENERATED_HMAC (Ruby): " + Base64.strict_encode64(hmac_signature)
EOF
)

echo
echo "--------------------------------"
echo $(PRIVATE_KEY=$(jq -Rs . < private_key.pem) SIGNATURE_DATA=$(cat signatureData.txt) ruby -e "$RUBY_CODE")
