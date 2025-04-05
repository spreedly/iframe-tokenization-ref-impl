#!/bin/sh

# Use command line arguments if provided, otherwise use environment variables
ENV_KEY=${1:-$ENV_KEY}
ACCESS_KEY=${2:-$ACCESS_KEY}
DOMAIN_NAME=${3:-$DOMAIN_NAME}
# Internal debug flag (not exposed to users)
DEBUG_PRIVATE_KEY=${4:-false}

# Check if required parameters are set
if [ -z "$ENV_KEY" ] || [ -z "$ACCESS_KEY" ] || [ -z "$DOMAIN_NAME" ]; then
    echo "Error: Required parameters are not set"
    echo "Usage: $0 [ENV_KEY] [ACCESS_KEY] [DOMAIN_NAME]"
    echo "Example: $0 'your_env' 'your_access_key' 'your_domain.com'"
    echo "Note: Parameters can also be set as environment variables: ENV_KEY, ACCESS_KEY, DOMAIN_NAME"
    exit 1
fi

# Generate a private key
openssl genrsa -out private_key.pem 3072

# Generate a public key from the private key (suppressing output)
openssl rsa -in private_key.pem -pubout -out public_key.pem > /dev/null 2>&1

# Generate a self-signed certificate, expires in 30 days
openssl req -new -x509 -days 30 -key private_key.pem -out cert.pem \
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
    --user "$ENV_KEY:$ACCESS_KEY" \
    --header 'content-type: application/json' \
    --data "$JSON_DATA" | jq -r '.certificate.token' > certificate_token.txt

nonce=$(uuidgen)
certificateToken=$(cat certificate_token.txt)
timestamp=$(date +%s)

# Generate a signature using the private key
PRIVATE_KEY_RAW=$(cat private_key.pem)

# Only output PRIVATE_KEY_RAW if debug flag is set
if [ "$DEBUG_PRIVATE_KEY" = "true" ]; then
  echo "DEBUG ─────────────────────────────────────"
  echo "PRIVATE_KEY_RAW: $PRIVATE_KEY_RAW"
  echo "DEBUG ─────────────────────────────────────"
fi

signature=$(echo -n "${nonce}${timestamp}${certificateToken}" | \
  openssl dgst -sha256 -hmac "$PRIVATE_KEY_RAW" -binary | \
  base64 -w 0)

echo
echo "╔═══════════════════════════════════════════════════╗"
echo "║   Example of how to generate the HMAC signature   ║	"
echo "╚═══════════════════════════════════════════════════╝"
echo "NONCE: $nonce"
echo " └─ randomly generated"
echo "TIMESTAMP: $timestamp"
echo " └─ current Unix timestamp"
echo "CERTIFICATE_TOKEN: $certificateToken"
echo "─────────────────────────────────────"
echo "SERVER_GENERATED_HMAC: $signature" | tr -d '\n' | cat
echo
echo " └─ generated using OpenSSL"

RUBY_CODE=$(cat <<EOF
require 'openssl'
require 'base64'
digest = OpenSSL::Digest.new('sha256')
hmac_signature = OpenSSL::HMAC.digest(digest, ENV['PRIVATE_KEY'], ENV['SIGNATURE_DATA'])
puts "SERVER_GENERATED_HMAC: " + Base64.strict_encode64(hmac_signature)
EOF
)
echo "─────────────────────────────────────"
echo $(PRIVATE_KEY=$PRIVATE_KEY_RAW SIGNATURE_DATA=$(echo $nonce$timestamp$certificateToken) ruby -e "$RUBY_CODE")
echo " └─ generated using Ruby"