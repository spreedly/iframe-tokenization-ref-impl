#!/bin/sh

# Use command line arguments if provided, otherwise use environment variables
ENV_KEY=${1:-$ENV_KEY}
ACCESS_KEY=${2:-$ACCESS_KEY}
DOMAIN_NAME=${3:-$DOMAIN_NAME}
SPREEDLY_ENDPOINT=${4:-$SPREEDLY_ENDPOINT}
# Internal debug flag (not exposed to users)
DEBUG_PRIVATE_KEY=${5:-false}

# Set default endpoint if not provided
SPREEDLY_ENDPOINT=${SPREEDLY_ENDPOINT:-"https://core.spreedly.com"}

# Check if required parameters are set
if [ -z "$ENV_KEY" ] || [ -z "$ACCESS_KEY" ] || [ -z "$DOMAIN_NAME" ]; then
    echo "Error: Required parameters are not set"
    echo "Usage: $0 [ENV_KEY] [ACCESS_KEY] [DOMAIN_NAME] [SPREEDLY_ENDPOINT]"
    echo "Example: $0 'your_env' 'your_access_key' 'your_domain.com' 'https://core.spreedly.com'"
    echo "Note: Parameters can also be set as environment variables: ENV_KEY, ACCESS_KEY, DOMAIN_NAME, SPREEDLY_ENDPOINT"
    exit 1
fi

# Generate a private key
openssl genrsa -out private_key.pem 3072

# Generate a public key from the private key (suppressing output)
openssl rsa -in private_key.pem -pubout -out public_key.pem > /dev/null 2>&1

# Generate a self-signed certificate, expires in 1 day
openssl req -new -x509 -days 1 -key private_key.pem -out cert.pem \
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
# Add -f flag to fail on HTTP errors
# Add -w flag to get the HTTP status code
HTTP_STATUS=$(curl -s -f -w "%{http_code}" --request POST \
    --url "${SPREEDLY_ENDPOINT}/v1/certificates" \
    --header 'accept: application/json' \
    --user "$ENV_KEY:$ACCESS_KEY" \
    --header 'content-type: application/json' \
    --data "$JSON_DATA" -o certificate_token.txt)

CURL_EXIT_CODE=$?

if [ $CURL_EXIT_CODE -ne 0 ]; then
    echo "Error: Failed to connect to Spreedly endpoint"
    echo "Endpoint: ${SPREEDLY_ENDPOINT}"
    echo "HTTP Status: ${HTTP_STATUS}"
    echo "Curl Exit Code: ${CURL_EXIT_CODE}"
    echo "Please check your network connection and endpoint URL"
    exit 1
fi

# Extract the certificate token from the response
certificateToken=$(jq -r '.certificate.token' certificate_token.txt)
if [ -z "$certificateToken" ] || [ "$certificateToken" = "null" ]; then
    echo "Error: Failed to get certificate token from response"
    echo "Response: $(cat certificate_token.txt)"
    exit 1
fi

nonce=$(uuidgen)
timestamp=$(date +%s)

# load your private key so we can use it to generate a signature
PRIVATE_KEY_RAW=$(cat private_key.pem)

# Only output PRIVATE_KEY_RAW if debug flag is set
if [ "$DEBUG_PRIVATE_KEY" = "true" ]; then
    echo "DEBUG ─────────────────────────────────────"
    echo "PRIVATE_KEY_RAW: $PRIVATE_KEY_RAW"
    echo "DEBUG ─────────────────────────────────────"
fi

# generate a signature using openssl and base64 encode it with no newlines
openssl_signature=$(echo -n "${nonce}${timestamp}${certificateToken}" | \
  openssl dgst -sha256 -hmac "$PRIVATE_KEY_RAW" -binary | \
  base64 -w 0)

RUBY_CODE=$(cat <<EOF
require 'openssl'
require 'base64'
digest = OpenSSL::Digest.new('sha256')
hmac_signature = OpenSSL::HMAC.digest(digest, ENV['PRIVATE_KEY'], ENV['SIGNATURE_DATA'])
puts "YOUR_SERVER_GENERATED_SIGNATURE: " + Base64.strict_encode64(hmac_signature)
EOF
)

echo
echo "╔═══════════════════════════════════════════════════╗"
echo "║   Example of how to generate the HMAC signature   ║	"
echo "╚═══════════════════════════════════════════════════╝"
echo "NONCE: $nonce"
echo " └─ randomly generated UUID"
echo "TIMESTAMP: $timestamp"
echo " └─ current Unix timestamp"
echo "CERTIFICATE_TOKEN: $certificateToken"
echo "─────────────────────────────────────"
echo "YOUR_SERVER_GENERATED_SIGNATURE: $openssl_signature"
echo " └─ generated using OpenSSL"
echo "─────────────────────────────────────"
echo $(PRIVATE_KEY=$PRIVATE_KEY_RAW SIGNATURE_DATA=$(echo $nonce$timestamp$certificateToken) ruby -e "$RUBY_CODE")
echo " └─ generated using Ruby"