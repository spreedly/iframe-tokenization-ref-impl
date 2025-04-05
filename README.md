# Iframe Tokenization Certificate Generator

This tool simplifies the process of generating a Spreedly certificate for iframe tokenization. It automates the certificate creation, signing, and registration with Spreedly's API.

## Prerequisites

- Docker installed on your system ([Get Docker](https://docs.docker.com/get-docker/))
- Your Spreedly environment key and access credentials, with secure tokenization enabled.

## Quick Start

Once the image is built, run these commmands, replacing the values accordingly:
- `your_env_key`: Your Spreedly environment key, login to obtain. *ONLY USE Non-Production values to test*.
- `your_access_key`: Your Spreedly access token or key. *ONLY USE Non-Production values to test*.
- `your_domain_name`: The domain for which you're generating the certificate, not enforced by us in any way, but helps keep things tidy (e.g., payment.example.com)

Here's a handy script to help you set things up:
```shell
echo "Enter your Spreedly ENVIRONMENT KEY"
read -s ENV_KEY
echo

echo "Enter your Spreedly ACCESS KEY"
read -s ACCESS_KEY
echo

DOMAIN_NAME=your_domain_name
```

## Building Locally

To build the image:

```bash
# Clone the repository
git clone https://github.com/spreedly/iframe-tokenization-ref-impl.git
cd iframe-tokenization-ref-impl

# Build the Docker image
docker build --no-cache -t iframe-tokenization-ref-impl .
```

Run the container:

```shell
docker run \
  -e ENV_KEY=$ENV_KEY \
  -e ACCESS_KEY=$ACCESS_KEY \
  -e DOMAIN_NAME=$DOMAIN_NAME \
  iframe-tokenization-ref-impl
```

Alternatively, you can start the container and run the script manually. 

```shell
docker run \
  -it --entrypoint /bin/sh \
  -e ENV_KEY=$ENV_KEY \
  -e ACCESS_KEY=$ACCESS_KEY \
  -e DOMAIN_NAME=$DOMAIN_NAME \
  iframe-tokenization-ref-impl
```

Then, once inside the container execute the script:
```shell
/app# ./create-cert.sh
```

## Output

The reference implementation tool will output:
- A randomly generated nonce
- A timestamp
- Your certificate token
- A server-generated signature

## How It Works

1. The tool generates a test one-time-use private/public key pair and certificate
2. Registers the certificate with Spreedly using your credentials
3. Creates a cryptographic signature for iframe tokenization
4. Output one time usage values you can use to test your implementation.

The Dockerized code runs the following equivalent reference implementations on AlpineLinux:
  - OpenSSL
  - Ruby

```bash
╔═══════════════════════════════════════════════════╗
║   Example of how to generate the HMAC signature   ║
╚═══════════════════════════════════════════════════╝
NONCE: 51a953a5-b257-4713-9984-2def87d1d2f1
 └─ randomly generated UUID
TIMESTAMP: 1743889760
 └─ current Unix timestamp
CERTIFICATE_TOKEN: 10JX90AV2EV9E1QH5P3RB568SD
─────────────────────────────────────
YOUR_GENERATED_SIGNATURE: TlNkS/uOGbDw+aJiiba+m2s8ai0yDaaZ7tDTlNd6+74= 
└─ generated using OpenSSL
─────────────────────────────────────
YOUR_GENERATED_SIGNATURE: TlNkS/uOGbDw+aJiiba+m2s8ai0yDaaZ7tDTlNd6+74=
 └─ generated using Ruby
```
5. Initialize Spreedly iFrame, e.g.:

```javascript
Spreedly.init("<Environment Key>", {  
  "numberEl": "spreedly-number",  
  "cvvEl": "spreedly-cvv",  
  "nonce": "<<NONCE>>>>",  // Generated by you on your server.
  "certificateToken": "<<CERTIFICATE_TOKEN>>",
  "timestamp": "<<TIMESTAMP>>", // Current timestamp
  "signature": "<<YOUR_GENERATED_SIGNATURE>>"
});
```


## Security Notes

- Your credentials are used only at runtime and are not stored in the image
- All cryptographic operations happen inside the container
- Private keys are not persisted after the container exits

## Troubleshooting

**Certificate Registration Fails**
- Verify your ENV_KEY and ACCESS_KEY are correct
- Ensure the DOMAIN_NAME matches your actual domain

**Other Issues**
- Try rebuilding with `--no-cache` to ensure a fresh build
- Check that your Docker installation is up to date

**Debugging Mode**

Note: this is intended for *Spreedly use only*.

```shell
SPREEDLY_ENDPOINT=<<Spreedly Use Only>>

DOCKER_HOST_IP=$(ifconfig en0 | grep inet | awk '$1=="inet" {print $2}')

docker run --add-host=$TEST_URL:$DOCKER_HOST_IP -e ENV_KEY=$ENV_KEY -e ACCESS_KEY=$ACCESS_KEY -e DOMAIN_NAME=$DOMAIN_NAME -e SPREEDLY_ENDPOINT="http://${SPREEDLY_ENDPOINT}"  iframe-tokenization-ref-impl
```

## License

Copyright © 2025 Spreedly. All rights reserved.