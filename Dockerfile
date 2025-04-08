FROM alpine:3.20

# Install required packages
RUN apk add --no-cache openssl curl jq uuidgen ruby python3 py3-pip py3-cryptography go nodejs npm openjdk17-jdk

# Create a directory for the script
WORKDIR /app

# Copy the scripts and version file into the container
COPY create-cert.sh /app/create-cert.sh
COPY VERSION /app/VERSION
COPY scripts/ruby /app/scripts/ruby
COPY scripts/python /app/scripts/python
COPY scripts/go /app/scripts/go
COPY scripts/typescript /app/scripts/typescript
COPY scripts/java /app/scripts/java

# Build the Go script
RUN cd /app/scripts/go && go build -o generate_signature generate_signature.go

# Install TypeScript dependencies and build
RUN cd /app/scripts/typescript && \
    npm install && \
    npm run build

# Compile Java code
RUN cd /app/scripts/java && \
    javac SignatureGenerator.java

# Make the scripts executable
RUN chmod +x /app/create-cert.sh /app/scripts/ruby/generate_signature.rb /app/scripts/python/generate_signature.py /app/scripts/go/generate_signature

# Set environment variables
ENV ENV_KEY=""
ENV ACCESS_KEY=""
ENV DOMAIN_NAME=""
ENV SPREEDLY_ENDPOINT="https://core.spreedly.com"

# Run the script with environment variables
ENTRYPOINT ["/bin/sh", "-c", "/app/create-cert.sh \"$ENV_KEY\" \"$ACCESS_KEY\" \"$DOMAIN_NAME\" \"$SPREEDLY_ENDPOINT\""] 