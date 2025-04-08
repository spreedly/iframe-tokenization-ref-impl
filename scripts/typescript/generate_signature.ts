import * as crypto from 'crypto';

const privateKey = process.env.PRIVATE_KEY;
const signatureData = process.env.SIGNATURE_DATA;

if (!privateKey || !signatureData) {
    console.error('Error: PRIVATE_KEY and SIGNATURE_DATA environment variables are required');
    process.exit(1);
}

try {
    const sign = crypto.createSign('SHA256');
    sign.update(signatureData);
    const signature = sign.sign(privateKey, 'base64');
    console.log(signature);
} catch (error) {
    console.error('Error generating signature:', error);
    process.exit(1);
} 