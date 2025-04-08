import java.security.Signature;
import java.security.PrivateKey;
import java.security.KeyFactory;
import java.security.spec.PKCS8EncodedKeySpec;
import java.util.Base64;

public class SignatureGenerator {
    public static void main(String[] args) {
        String privateKeyPem = System.getenv("PRIVATE_KEY");
        String signatureData = System.getenv("SIGNATURE_DATA");

        if (privateKeyPem == null || signatureData == null) {
            System.err.println("Error: PRIVATE_KEY and SIGNATURE_DATA environment variables are required");
            System.exit(1);
        }

        try {
            // Remove header, footer, and newlines from PEM
            privateKeyPem = privateKeyPem.replace("-----BEGIN PRIVATE KEY-----", "")
                                       .replace("-----END PRIVATE KEY-----", "")
                                       .replaceAll("\\s", "");

            // Decode base64 to get the raw key bytes
            byte[] keyBytes = Base64.getDecoder().decode(privateKeyPem);
            
            // Create PKCS8EncodedKeySpec
            PKCS8EncodedKeySpec keySpec = new PKCS8EncodedKeySpec(keyBytes);
            
            // Get RSA key factory
            KeyFactory keyFactory = KeyFactory.getInstance("RSA");
            
            // Generate private key
            PrivateKey privateKey = keyFactory.generatePrivate(keySpec);
            
            // Create signature instance
            Signature signature = Signature.getInstance("SHA256withRSA");
            
            // Initialize with private key
            signature.initSign(privateKey);
            
            // Update with data
            signature.update(signatureData.getBytes());
            
            // Generate signature
            byte[] signedBytes = signature.sign();
            
            // Convert to base64
            String base64Signature = Base64.getEncoder().encodeToString(signedBytes);
            
            // Print the signature
            System.out.println(base64Signature);
        } catch (Exception e) {
            System.err.println("Error generating signature: " + e.getMessage());
            System.exit(1);
        }
    }
} 