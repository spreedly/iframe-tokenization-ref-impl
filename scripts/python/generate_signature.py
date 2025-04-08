#!/usr/bin/env python3

import os
import base64
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import padding
from cryptography.hazmat.primitives.serialization import load_pem_private_key

# Get the private key and signature data from environment variables
private_key_raw = os.environ['PRIVATE_KEY'].encode('utf-8')
signature_data = os.environ['SIGNATURE_DATA'].encode('utf-8')

# Load the private key
private_key = load_pem_private_key(private_key_raw, password=None)

# Generate the signature
signature = private_key.sign(
    signature_data,
    padding.PKCS1v15(),
    hashes.SHA256()
)

# Output the base64 encoded signature
print(base64.b64encode(signature).decode('utf-8')) 