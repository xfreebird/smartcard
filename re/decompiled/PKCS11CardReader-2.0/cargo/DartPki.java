/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package cargo;

import java.io.ByteArrayInputStream;
import java.math.BigInteger;
import java.security.AlgorithmParameters;
import java.security.GeneralSecurityException;
import java.security.KeyFactory;
import java.security.MessageDigest;
import java.security.PublicKey;
import java.security.Signature;
import java.security.cert.CertificateException;
import java.security.cert.CertificateFactory;
import java.security.cert.X509Certificate;
import java.security.interfaces.ECPublicKey;
import java.security.interfaces.RSAPublicKey;
import java.security.spec.ECGenParameterSpec;
import java.security.spec.ECParameterSpec;
import java.security.spec.ECPoint;
import java.security.spec.ECPublicKeySpec;
import java.security.spec.RSAPublicKeySpec;
import java.time.Duration;
import java.time.Instant;
import java.util.Base64;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class DartPki {
    private static final Logger logger = LoggerFactory.getLogger(DartPki.class);

    public static X509Certificate certFromDer(byte[] der) {
        if (der == null) {
            return null;
        }
        try {
            CertificateFactory cf = CertificateFactory.getInstance("X.509", "BC");
            ByteArrayInputStream in = new ByteArrayInputStream(der);
            return (X509Certificate)cf.generateCertificate(in);
        }
        catch (GeneralSecurityException ex) {
            logger.error("", (Throwable)ex);
            return null;
        }
    }

    public static boolean isValid(byte[] der) {
        X509Certificate cert = DartPki.certFromDer(der);
        if (cert == null) {
            return false;
        }
        try {
            cert.checkValidity();
            return true;
        }
        catch (CertificateException ex) {
            logger.error("", (Throwable)ex);
            return false;
        }
    }

    public static RSAPublicKey rsaKeyFromBytes(byte[] modulusBytes, byte[] exponentBytes) {
        if (modulusBytes == null || exponentBytes == null) {
            return null;
        }
        BigInteger modulus = new BigInteger(1, modulusBytes);
        BigInteger exponent = new BigInteger(1, exponentBytes);
        RSAPublicKeySpec spec = new RSAPublicKeySpec(modulus, exponent);
        try {
            KeyFactory factory = KeyFactory.getInstance("RSA", "BC");
            return (RSAPublicKey)factory.generatePublic(spec);
        }
        catch (GeneralSecurityException ex) {
            logger.error("", (Throwable)ex);
            return null;
        }
    }

    public static ECPublicKey ecKeyFromBytes(byte[] affineX, byte[] affineY, String curveName) {
        if (affineX == null || affineY == null || curveName == null) {
            return null;
        }
        BigInteger x = new BigInteger(1, affineX);
        BigInteger y = new BigInteger(1, affineY);
        ECPoint w = new ECPoint(x, y);
        try {
            AlgorithmParameters algoParams = AlgorithmParameters.getInstance("EC", "BC");
            algoParams.init(new ECGenParameterSpec(curveName));
            ECParameterSpec params = algoParams.getParameterSpec(ECParameterSpec.class);
            ECPublicKeySpec spec = new ECPublicKeySpec(w, params);
            KeyFactory factory = KeyFactory.getInstance("EC", "BC");
            return (ECPublicKey)factory.generatePublic(spec);
        }
        catch (GeneralSecurityException ex) {
            logger.error("", (Throwable)ex);
            return null;
        }
    }

    public static boolean verify(PublicKey key, byte[] signatureBytes, byte[] data) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256", "BC");
            digest.update(data);
            byte[] hash = digest.digest();
            Signature sign = Signature.getInstance("SHA256withRSA", "BC");
            sign.initVerify(key);
            sign.update(hash);
            return sign.verify(signatureBytes);
        }
        catch (GeneralSecurityException ex) {
            logger.error("", (Throwable)ex);
            return false;
        }
    }

    public static boolean checkNew(String new_certificate, String issuer_certificate) {
        byte[] newDer = Base64.getDecoder().decode(new_certificate);
        X509Certificate newCer = DartPki.certFromDer(newDer);
        Instant now = Instant.now();
        Instant notBefore = newCer.getNotBefore().toInstant();
        Instant notAfter = newCer.getNotAfter().toInstant();
        Duration window = Duration.ofHours(1L);
        return now.isAfter(notBefore.minus(window)) && now.isBefore(notAfter);
    }
}

