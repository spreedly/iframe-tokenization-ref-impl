#!/usr/bin/env ruby

require 'openssl'
require 'base64'

# Get the private key and signature data from environment variables
private_key_raw = ENV['PRIVATE_KEY']
signature_data = ENV['SIGNATURE_DATA']

# Generate the signature
digest = OpenSSL::Digest.new('sha256')
private_key = OpenSSL::PKey.read(private_key_raw)
signature = private_key.sign(digest, signature_data)

# Output the base64 encoded signature
puts Base64.strict_encode64(signature) 