# Iframe Secure Tokenization - Reference Implementation

This tool demonstrates the process of generating a test certificate for Spreedly iFrame Secure Tokenization, with automated certificate creation, registration with Spreedly's API, and request signing.

The Dockerized code runs the following equivalent reference implementations on AlpineLinux:
  - OpenSSL
  - Ruby
  - Python
  - Go
  - TypeScript
  - Java

For a step-by-step guide, see [Step-by-Step: Using Certificates for Enhanced iFrame Security
](https://developer.spreedly.com/docs/using-certificates-iframe-security).

## Disclaimer

⚠️ **Important Note**: These reference implementations are provided as examples only. Spreedly cannot provide support for debugging or modifying these implementations. Users are responsible for ensuring the security and correctness of any modifications they make to these reference implementations.

## Prerequisites

- Docker installed on your system ([Get Docker](https://docs.docker.com/get-docker/))
- Your Spreedly environment key and access credentials, with [secure tokenization enabled](https://developer.spreedly.com/docs/iframe-api-lifecycle#enabling-authentication).

## Quick Start

### Build the image

```bash
# Clone the repository
git clone https://github.com/spreedly/iframe-tokenization-ref-impl.git
cd iframe-tokenization-ref-impl
```


Then, create a local versioned image:

```shell
# Read version from VERSION file
VERSION=$(cat VERSION)

# Build the image with both version and latest tags
docker build --no-cache \
  -t iframe-tokenization-ref-impl:${VERSION} \
  -t iframe-tokenization-ref-impl:latest .

# Print version information
echo "Built image with version: ${VERSION}"
echo "To list all versions: docker images iframe-tokenization-ref-impl"
echo "To inspect a specific version: docker inspect iframe-tokenization-ref-impl:${VERSION}" 
```

### Execute the script

> ⚠️ **Important**: ONLY USE Non-Production key values in your testing ⚠️

Once the Docker image is built, you will need these values:
- `your_env_key`: Your Spreedly environment key, login to obtain.
- `your_access_key`: Your Spreedly access token or key.
- `your_domain_name`: The domain for which you're generating the certificate. This is not enforced by us in any way, but helps keep things tidy (e.g., `payment.example.com`)

Here's a handy shell script to help you set things up, adjust as needed by your specific OS:
```shell
echo "Enter your Spreedly ENVIRONMENT KEY"
read -s ENV_KEY
echo

echo "Enter your Spreedly ACCESS KEY"
read -s ACCESS_KEY
echo

DOMAIN_NAME=your_domain_name
```

Run the container:

```shell
docker run \
  -e ENV_KEY=$ENV_KEY \
  -e ACCESS_KEY=$ACCESS_KEY \
  -e DOMAIN_NAME=$DOMAIN_NAME \
  iframe-tokenization-ref-impl
```

### Manual execution

Alternatively, if you're interested in how this works, take a look at `create-cert.sh` script and start the container, jump into its shell and run the script manually.

```shell
docker run \
  -it --entrypoint /bin/sh \
  -e ENV_KEY=$ENV_KEY \
  -e ACCESS_KEY=$ACCESS_KEY \
  -e DOMAIN_NAME=$DOMAIN_NAME \
  iframe-tokenization-ref-impl

# wait for container to start, then issue this command at its shell prompt:

./create-cert.sh
```

## Output

The reference implementation tool will output:
- A randomly generated nonce.
- A timestamp.
- A certificate token that you can use to test.
- Server-generated signatures from multiple implementations.

## How It Works

1. The tool generates a test one-time-use private/public key pair and certificate with a 1 day expiration date.
2. Registers the test certificate with Spreedly using your credentials.
3. Creates a cryptographic one-time use signature for iframe tokenization.


```shell
╔═══════════════════════════════════════════════════╗
║     Example of how to generate the signature     ║
╚═══════════════════════════════════════════════════╝
NONCE: 51a953a5-b257-4713-9984-2def87d1d2f1
 └─ randomly generated UUID
TIMESTAMP: 1743889760
 └─ current Unix timestamp
CERTIFICATE_TOKEN: 10JX90AV2EV9E1QH5P3RB568SD
─────────────────────────────────────
ONE_TIME_SIGNATURE: TlNkS/uOGbDw+aJiiba+m2s8ai0yDaaZ7tDTlNd6+74=
└─ generated using OpenSSL
─────────────────────────────────────
ONE_TIME_SIGNATURE: TlNkS/uOGbDw+aJiiba+m2s8ai0yDaaZ7tDTlNd6+74=
 └─ generated using Ruby
─────────────────────────────────────
ONE_TIME_SIGNATURE: TlNkS/uOGbDw+aJiiba+m2s8ai0yDaaZ7tDTlNd6+74=
 └─ generated using Python
─────────────────────────────────────
ONE_TIME_SIGNATURE: TlNkS/uOGbDw+aJiiba+m2s8ai0yDaaZ7tDTlNd6+74=
 └─ generated using Go
─────────────────────────────────────
ONE_TIME_SIGNATURE: TlNkS/uOGbDw+aJiiba+m2s8ai0yDaaZ7tDTlNd6+74=
 └─ generated using TypeScript
─────────────────────────────────────
ONE_TIME_SIGNATURE: TlNkS/uOGbDw+aJiiba+m2s8ai0yDaaZ7tDTlNd6+74=
 └─ generated using Java
```
5. Initialize Spreedly iFrame, e.g.:

```javascript
Spreedly.init("<Environment Key>", {
  "numberEl": "spreedly-number",
  "cvvEl": "spreedly-cvv",
  "nonce": "<<NONCE>>",
  "timestamp": "<<TIMESTAMP>>", 
  "certificateToken": "<<CERTIFICATE_TOKEN>>",
"signature": "<<ONE_TIME_SIGNATURE>>"
});
```


## Security Notes

- Your credentials are used only at runtime and are not stored in the image.
- All cryptographic operations happen inside the container.
- Private keys are _not persisted_ after the container exits.

## Troubleshooting

**Certificate Registration Fails**
- Verify your ENV_KEY and ACCESS_KEY are correct.

**Version Mismatch**
- If you're experiencing unexpected behavior, verify that the container version matches the VERSION file:

```shell
  # Check the version in your VERSION file
  cat VERSION
  
  # Check the version of your running container
  docker run --rm iframe-tokenization-ref-impl:latest env | grep VERSION
```

If versions don't match, rebuild the container as per the instructions above.

**Other Issues**
- Try rebuilding with `--no-cache` to ensure a fresh build.
- Check that your Docker installation is up to date.

**Debugging Mode**

Note: this is intended for *Spreedly use only*.

```shell
SPREEDLY_ENDPOINT="<<Spreedly Use Only>>"

DOCKER_HOST_IP=$(ifconfig en0 | grep inet | awk '$1=="inet" {print $2}')

docker run --add-host=$TEST_URL:$DOCKER_HOST_IP -e ENV_KEY=$ENV_KEY -e ACCESS_KEY=$ACCESS_KEY -e DOMAIN_NAME=$DOMAIN_NAME -e SPREEDLY_ENDPOINT="http://${SPREEDLY_ENDPOINT}"  iframe-tokenization-ref-impl
```

## License

Copyright © 2025 Spreedly. All rights reserved.