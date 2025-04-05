FROM alpine:3.20

# Install required packages
RUN apk add --no-cache openssl curl jq uuidgen ruby

# Create a directory for the script
WORKDIR /app

# Copy the script into the container
COPY create-cert.sh /app/create-cert.sh

# Make the script executable
RUN chmod +x /app/create-cert.sh

# Set environment variables
ENV ENV_KEY=""
ENV ACCESS_KEY=""
ENV DOMAIN_NAME=""
ENV SPREEDLY_ENDPOINT="https://core.spreedly.com"

# Run the script with environment variables
ENTRYPOINT ["/bin/sh", "-c", "/app/create-cert.sh \"$ENV_KEY\" \"$ACCESS_KEY\" \"$DOMAIN_NAME\" \"$SPREEDLY_ENDPOINT\""] 