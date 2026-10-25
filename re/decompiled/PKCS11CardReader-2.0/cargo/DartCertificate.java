/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  ghesar.DNParser
 *  iaik.pkcs.pkcs11.Token
 *  iaik.pkcs.pkcs11.objects.X509PublicKeyCertificate
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package cargo;

import cargo.DartPki;
import ghesar.DNParser;
import iaik.pkcs.pkcs11.Token;
import iaik.pkcs.pkcs11.objects.X509PublicKeyCertificate;
import java.security.cert.CertificateEncodingException;
import java.security.cert.X509Certificate;
import java.time.Duration;
import java.time.Instant;
import java.util.Base64;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class DartCertificate {
    private static final Logger logger = LoggerFactory.getLogger(DartCertificate.class);
    private final Token token;
    private byte[] id;
    private X509Certificate cert;

    public DartCertificate(Token token) {
        this.token = token;
    }

    public boolean decode(X509PublicKeyCertificate pkcsCert) {
        this.id = pkcsCert.getId().getByteArrayValue();
        byte[] der = pkcsCert.getValue().getByteArrayValue();
        if (this.id == null) {
            return false;
        }
        this.cert = DartPki.certFromDer(der);
        return this.cert != null;
    }

    public Token getToken() {
        return this.token;
    }

    public byte[] getId() {
        return this.id;
    }

    public X509Certificate getCert() {
        return this.cert;
    }

    public byte[] getCertBytes() {
        try {
            return this.cert.getEncoded();
        }
        catch (CertificateEncodingException ex) {
            return null;
        }
    }

    public String getCert_b64() {
        byte[] der;
        try {
            der = this.cert.getEncoded();
        }
        catch (CertificateEncodingException ex) {
            return null;
        }
        if (der == null) {
            return null;
        }
        return Base64.getEncoder().encodeToString(der);
    }

    public boolean hasSpecificIssuer() {
        String name = this.cert.getIssuerX500Principal().getName();
        DNParser dn = new DNParser(name);
        String country = dn.get("C");
        String cn = dn.get("CN");
        return "MD".equals(country) && ("MoldSign QCA 3A".equals(cn) || "MDQSign".equals(cn));
    }

    public boolean isNearingExpiration() {
        Instant now = Instant.now();
        Instant notBefore = this.cert.getNotBefore().toInstant();
        Instant notAfter = this.cert.getNotAfter().toInstant();
        Duration window = Duration.ofDays(30L);
        return now.isAfter(notBefore) && now.isAfter(notAfter.minus(window)) && now.isBefore(notAfter);
    }

    public String getOrganization() {
        String name = this.cert.getSubjectX500Principal().getName();
        DNParser dn = new DNParser(name);
        return dn.get("O");
    }

    public boolean isAlReady(X509Certificate oth) {
        logger.info("isAlReady 0");
        if (this.cert.getSerialNumber().equals(oth.getSerialNumber())) {
            return false;
        }
        logger.info("isAlReady 1");
        String name1 = this.cert.getSubjectX500Principal().getName();
        DNParser dn1 = new DNParser(name1);
        String name2 = oth.getSubjectX500Principal().getName();
        DNParser dn2 = new DNParser(name2);
        String cn1 = dn1.get("CN");
        String cn2 = dn2.get("CN");
        if (cn1 == null || !cn1.equals(cn2)) {
            return false;
        }
        logger.info("isAlReady 2");
        String name = oth.getIssuerX500Principal().getName();
        DNParser dn = new DNParser(name);
        String country = dn.get("C");
        String cn = dn.get("CN");
        if (!"MD".equals(country) || !"MoldSign QCA 3A".equals(cn) && !"MDQSign".equals(cn)) {
            return false;
        }
        logger.info("isAlReady 3");
        Instant now = Instant.now();
        Instant notBefore = oth.getNotBefore().toInstant();
        Instant notAfter = oth.getNotAfter().toInstant();
        Duration window = Duration.ofDays(30L);
        if (!now.isAfter(notBefore) || !now.isBefore(notAfter.minus(window))) {
            return false;
        }
        logger.info("isAlReady 4");
        return true;
    }
}

