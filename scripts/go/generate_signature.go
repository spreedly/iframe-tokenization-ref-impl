package main

import (
	"crypto"
	"crypto/rsa"
	"crypto/sha256"
	"crypto/x509"
	"encoding/base64"
	"encoding/pem"
	"os"
)

func main() {
	// Get the private key and signature data from environment variables
	privateKeyPEM := os.Getenv("PRIVATE_KEY")
	signatureData := os.Getenv("SIGNATURE_DATA")

	// Decode the PEM block
	block, _ := pem.Decode([]byte(privateKeyPEM))
	if block == nil {
		panic("failed to parse PEM block containing the private key")
	}

	// Parse the private key
	parsedKey, err := x509.ParsePKCS8PrivateKey(block.Bytes)
	if err != nil {
		panic(err)
	}

	// Type assert to RSA private key
	privateKey, ok := parsedKey.(*rsa.PrivateKey)
	if !ok {
		panic("key is not an RSA private key")
	}

	// Hash the data
	hashed := sha256.Sum256([]byte(signatureData))

	// Sign the data
	signature, err := rsa.SignPKCS1v15(nil, privateKey, crypto.SHA256, hashed[:])
	if err != nil {
		panic(err)
	}

	// Output the base64 encoded signature
	print(base64.StdEncoding.EncodeToString(signature))
} 