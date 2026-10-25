/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  iaik.asn1.ASN1
 *  iaik.asn1.ASN1Object
 *  iaik.asn1.CodingException
 *  iaik.asn1.DerCoder
 *  iaik.asn1.INTEGER
 *  iaik.asn1.ObjectID
 *  iaik.asn1.structures.Name
 *  iaik.pkcs.pkcs11.Mechanism
 *  iaik.pkcs.pkcs11.Module
 *  iaik.pkcs.pkcs11.Session
 *  iaik.pkcs.pkcs11.Slot
 *  iaik.pkcs.pkcs11.Token
 *  iaik.pkcs.pkcs11.TokenException
 *  iaik.pkcs.pkcs11.TokenInfo
 *  iaik.pkcs.pkcs11.objects.ECDSAPrivateKey
 *  iaik.pkcs.pkcs11.objects.ECDSAPublicKey
 *  iaik.pkcs.pkcs11.objects.Key
 *  iaik.pkcs.pkcs11.objects.KeyPair
 *  iaik.pkcs.pkcs11.objects.Object
 *  iaik.pkcs.pkcs11.objects.PrivateKey
 *  iaik.pkcs.pkcs11.objects.PublicKey
 *  iaik.pkcs.pkcs11.objects.RSAPrivateKey
 *  iaik.pkcs.pkcs11.objects.RSAPublicKey
 *  iaik.pkcs.pkcs11.objects.X509PublicKeyCertificate
 *  iaik.x509.X509Certificate
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package cargo;

import cargo.DartCertificate;
import cargo.DartKey;
import cargo.DartPki;
import cargo.DartSignature;
import cargo.Rust;
import cargo.model.TokenInformation;
import iaik.asn1.ASN1;
import iaik.asn1.ASN1Object;
import iaik.asn1.CodingException;
import iaik.asn1.DerCoder;
import iaik.asn1.INTEGER;
import iaik.asn1.ObjectID;
import iaik.asn1.structures.Name;
import iaik.pkcs.pkcs11.Mechanism;
import iaik.pkcs.pkcs11.Module;
import iaik.pkcs.pkcs11.Session;
import iaik.pkcs.pkcs11.Slot;
import iaik.pkcs.pkcs11.Token;
import iaik.pkcs.pkcs11.TokenException;
import iaik.pkcs.pkcs11.TokenInfo;
import iaik.pkcs.pkcs11.objects.ECDSAPrivateKey;
import iaik.pkcs.pkcs11.objects.ECDSAPublicKey;
import iaik.pkcs.pkcs11.objects.Key;
import iaik.pkcs.pkcs11.objects.KeyPair;
import iaik.pkcs.pkcs11.objects.Object;
import iaik.pkcs.pkcs11.objects.PrivateKey;
import iaik.pkcs.pkcs11.objects.PublicKey;
import iaik.pkcs.pkcs11.objects.RSAPrivateKey;
import iaik.pkcs.pkcs11.objects.RSAPublicKey;
import iaik.pkcs.pkcs11.objects.X509PublicKeyCertificate;
import iaik.x509.X509Certificate;
import java.io.IOException;
import java.math.BigInteger;
import java.security.cert.CertificateException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Base64;
import java.util.Date;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicLong;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class DartModule
implements AutoCloseable {
    private static final Logger logger = LoggerFactory.getLogger(DartModule.class);
    private static final AtomicLong counter = new AtomicLong(1L);
    private static final boolean skipPut = false;
    private static final boolean skipDelete = false;
    private final char[] password;
    private Module module = null;
    private boolean isExternal = false;
    private List<Token> tokenList = null;

    DartModule(char[] pin) {
        this.password = pin;
    }

    private static long atomicLongKey() {
        return counter.getAndIncrement();
    }

    public void init(String library) throws IOException, TokenException {
        this.module = Module.getInstance((String)library);
        this.module.initialize(null);
    }

    @Override
    public void close() throws Exception {
        if (this.module != null && !this.isExternal) {
            try {
                this.module.finalize(null);
            }
            catch (Exception ex) {
                logger.error("", (Throwable)ex);
                throw ex;
            }
        }
    }

    public void bridge(Module module) {
        this.module = module;
        this.isExternal = true;
    }

    public TokenInformation getTokenInformation(Token token) {
        TokenInfo info;
        try {
            info = token.getTokenInfo();
        }
        catch (TokenException ex) {
            logger.error("", (Throwable)ex);
            return null;
        }
        return new TokenInformation(info.getLabel().trim(), info.getManufacturerID().trim(), info.getModel().trim(), info.getSerialNumber().trim(), token.getSlot().getSlotID(), token.getSlot().getModule().toString().trim());
    }

    public void scanTokens() throws TokenException {
        Slot[] slots;
        if (this.module == null) {
            return;
        }
        this.tokenList = new ArrayList<Token>();
        for (Slot slot : slots = this.module.getSlotList(true)) {
            Token token = slot.getToken();
            this.tokenList.add(token);
        }
    }

    public Token getToken(long id) {
        if (this.module == null || this.tokenList == null) {
            return null;
        }
        for (Token token : this.tokenList) {
            logger.info("token: {}", (java.lang.Object)token.getTokenID());
        }
        for (Token token : this.tokenList) {
            if (token.getTokenID() != id) continue;
            return token;
        }
        return null;
    }

    public Map<Long, DartCertificate> scanCertificates() throws TokenException {
        if (this.module == null || this.tokenList == null) {
            return null;
        }
        HashMap<Long, DartCertificate> certList = new HashMap<Long, DartCertificate>();
        for (Token token : this.tokenList) {
            this.searchCertificates(token, certList);
        }
        return certList;
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    private void searchCertificates(Token token, Map<Long, DartCertificate> certList) throws TokenException {
        Session session = null;
        try {
            session = token.openSession(true, false, null, null);
            X509PublicKeyCertificate template = new X509PublicKeyCertificate();
            session.findObjectsInit((Object)template);
            try {
                Object[] arr;
                while ((arr = session.findObjects(1)).length != 0) {
                    X509PublicKeyCertificate certObj;
                    DartCertificate dart;
                    boolean ok;
                    Object pkcsObj = arr[0];
                    if (!(pkcsObj instanceof X509PublicKeyCertificate) || !(ok = (dart = new DartCertificate(token)).decode(certObj = (X509PublicKeyCertificate)pkcsObj))) continue;
                    certList.put(DartModule.atomicLongKey(), dart);
                }
            }
            finally {
                try {
                    session.findObjectsFinal();
                }
                catch (Exception ex) {
                    logger.error("", (Throwable)ex);
                }
            }
        }
        finally {
            if (session != null) {
                try {
                    session.closeSession();
                }
                catch (Exception ex) {
                    logger.error("", (Throwable)ex);
                }
            }
        }
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    public DartKey generate(Token token, int algo) throws TokenException {
        Session session = null;
        boolean logedin = false;
        try {
            boolean ok;
            DartKey dart;
            RSAPrivateKey privateKeyTemplate;
            RSAPublicKey publicKeyTemplate;
            Mechanism mechanism;
            session = token.openSession(true, true, null, null);
            if (this.password != null) {
                session.login(true, this.password);
                logedin = true;
            }
            byte[] id = session.generateRandom(32);
            logger.info("generate() new key_id: {}", (java.lang.Object)Rust.bytesToHex(id));
            char[] label = "Moldova".toCharArray();
            Date date = new Date();
            if (algo == 1) {
                mechanism = new Mechanism(0L);
                pub = new RSAPublicKey();
                pri = new RSAPrivateKey();
                pub.getModulusBits().setLongValue(Long.valueOf(2048L));
                publicKeyTemplate = pub;
                privateKeyTemplate = pri;
            } else if (algo == 2) {
                mechanism = new Mechanism(4160L);
                pub = new ECDSAPublicKey();
                pri = new ECDSAPrivateKey();
                ObjectID curveObjectID = new ObjectID("1.2.840.10045.3.1.7");
                byte[] curve = DerCoder.encode((ASN1Object)curveObjectID);
                pub.getEcdsaParams().setByteArrayValue(curve);
                publicKeyTemplate = pub;
                privateKeyTemplate = pri;
            } else {
                logger.error("");
                DartKey pub = null;
                return pub;
            }
            publicKeyTemplate.getToken().setBooleanValue(Boolean.valueOf(true));
            publicKeyTemplate.getId().setByteArrayValue(id);
            publicKeyTemplate.getLabel().setCharArrayValue(label);
            publicKeyTemplate.getStartDate().setDateValue(date);
            privateKeyTemplate.getToken().setBooleanValue(Boolean.valueOf(true));
            privateKeyTemplate.getId().setByteArrayValue(id);
            privateKeyTemplate.getLabel().setCharArrayValue(label);
            privateKeyTemplate.getStartDate().setDateValue(date);
            KeyPair key = session.generateKeyPair(mechanism, (Object)publicKeyTemplate, (Object)privateKeyTemplate);
            PublicKey pubKey = key.getPublicKey();
            if (pubKey instanceof RSAPublicKey) {
                dart = new DartKey(id);
                boolean ok2 = dart.decodeRSA((RSAPublicKey)pubKey);
                if (ok2) {
                    DartKey dartKey = dart;
                    return dartKey;
                }
            } else if (pubKey instanceof ECDSAPublicKey && (ok = (dart = new DartKey(id)).decodeEC((ECDSAPublicKey)pubKey))) {
                DartKey dartKey = dart;
                return dartKey;
            }
        }
        finally {
            if (logedin) {
                try {
                    session.logout();
                }
                catch (Exception ex) {
                    logger.error("", (Throwable)ex);
                }
            }
            if (session != null) {
                try {
                    session.closeSession();
                }
                catch (Exception ex) {
                    logger.error("", (Throwable)ex);
                }
            }
        }
        return null;
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    public DartSignature sign(Token token, byte[] keyId, byte[] dataToSign) throws TokenException {
        Session session = null;
        boolean logedin = false;
        try {
            session = token.openSession(true, false, null, null);
            if (this.password != null) {
                session.login(true, this.password);
                logedin = true;
            }
            Mechanism mechanism1 = new Mechanism(592L);
            session.digestInit(mechanism1);
            byte[] hash = session.digest(dataToSign);
            logger.info("sign() hash: {}", (java.lang.Object)Base64.getEncoder().encodeToString(hash));
            RSAPrivateKey key = this.searchPrivateKey(session, keyId);
            if (key == null) {
                logger.error("sign() private key not found");
                DartSignature dartSignature = null;
                return dartSignature;
            }
            Mechanism mechanism2 = new Mechanism(64L);
            session.signInit(mechanism2, (Key)key);
            byte[] signature = session.sign(hash);
            if (signature != null) {
                DartSignature dartSignature = new DartSignature(signature);
                return dartSignature;
            }
        }
        finally {
            if (logedin) {
                try {
                    session.logout();
                }
                catch (Exception ex) {
                    logger.error("", (Throwable)ex);
                }
            }
            if (session != null) {
                try {
                    session.closeSession();
                }
                catch (Exception ex) {
                    logger.error("", (Throwable)ex);
                }
            }
        }
        return null;
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    private RSAPrivateKey searchPrivateKey(Session session, byte[] keyId) throws TokenException {
        RSAPrivateKey privateKey;
        block4: {
            logger.info("searchPrivateKey: {}", (java.lang.Object)Rust.bytesToHex(keyId));
            privateKey = null;
            RSAPrivateKey searchTemplate = new RSAPrivateKey();
            searchTemplate.getId().setByteArrayValue(keyId);
            session.findObjectsInit((Object)searchTemplate);
            try {
                RSAPrivateKey key;
                Object[] arr;
                Object pkcsObj;
                do {
                    if ((arr = session.findObjects(1)).length != 0) continue;
                    break block4;
                } while (!((pkcsObj = arr[0]) instanceof RSAPrivateKey) || !Arrays.equals(keyId, (key = (RSAPrivateKey)pkcsObj).getId().getByteArrayValue()));
                privateKey = key;
            }
            finally {
                session.findObjectsFinal();
            }
        }
        return privateKey;
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    public void delete(Token token) throws TokenException {
        Session session = null;
        boolean logedin = false;
        try {
            session = token.openSession(true, true, null, null);
            if (this.password != null) {
                session.login(true, this.password);
                logedin = true;
            }
            HashMap<String, X509PublicKeyCertificate> certificate = new HashMap<String, X509PublicKeyCertificate>();
            HashMap<String, PublicKey> publicKey = new HashMap<String, PublicKey>();
            HashMap<String, PrivateKey> privateKey = new HashMap<String, PrivateKey>();
            HashSet<Object> unknown = new HashSet<Object>();
            session.findObjectsInit(null);
            try {
                Object[] arr;
                while ((arr = session.findObjects(1)).length != 0) {
                    Object pkcsObj = arr[0];
                    if (pkcsObj instanceof X509PublicKeyCertificate) {
                        X509PublicKeyCertificate x509PublicKeyCertificate = (X509PublicKeyCertificate)pkcsObj;
                        certificate.put(Rust.bytesToHex(x509PublicKeyCertificate.getId().getByteArrayValue()), x509PublicKeyCertificate);
                        continue;
                    }
                    if (pkcsObj instanceof PublicKey) {
                        PublicKey key = (PublicKey)pkcsObj;
                        publicKey.put(Rust.bytesToHex(key.getId().getByteArrayValue()), key);
                        continue;
                    }
                    if (pkcsObj instanceof PrivateKey) {
                        PrivateKey key = (PrivateKey)pkcsObj;
                        privateKey.put(Rust.bytesToHex(key.getId().getByteArrayValue()), key);
                        continue;
                    }
                    unknown.add(pkcsObj);
                }
            }
            finally {
                session.findObjectsFinal();
            }
            logger.info("delete() found {} {} {} {}", new java.lang.Object[]{certificate.size(), publicKey.size(), privateKey.size(), unknown.size()});
            HashSet<String> drop = new HashSet<String>();
            for (String string : certificate.keySet()) {
                if (!publicKey.containsKey(string) || !privateKey.containsKey(string)) {
                    logger.info("delete certificate {}", (java.lang.Object)string);
                    session.destroyObject((Object)certificate.get(string));
                    drop.add(string);
                    continue;
                }
                X509PublicKeyCertificate cert = (X509PublicKeyCertificate)certificate.get(string);
                byte[] certDer = cert.getValue().getByteArrayValue();
                if (DartPki.isValid(certDer)) continue;
                logger.info("delete expired certificate {}", (java.lang.Object)string);
                session.destroyObject((Object)certificate.get(string));
                drop.add(string);
            }
            certificate.keySet().removeAll(drop);
            for (String string : publicKey.keySet()) {
                if (certificate.containsKey(string)) continue;
                logger.info("delete publicKey {}", (java.lang.Object)string);
                session.destroyObject((Object)publicKey.get(string));
            }
            for (String string : privateKey.keySet()) {
                if (certificate.containsKey(string)) continue;
                logger.info("delete privateKey {}", (java.lang.Object)string);
                session.destroyObject((Object)privateKey.get(string));
            }
            for (Object object : unknown) {
                logger.info("delete unknown");
                session.destroyObject(object);
            }
        }
        finally {
            if (logedin) {
                try {
                    session.logout();
                }
                catch (Exception ex) {
                    logger.error("", (Throwable)ex);
                }
            }
            if (session != null) {
                try {
                    session.closeSession();
                }
                catch (Exception ex) {
                    logger.error("", (Throwable)ex);
                }
            }
        }
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    public boolean putCertificate(Token token, byte[] certDer, byte[] newid, byte[] oldId) throws TokenException {
        byte[] serial;
        X509Certificate certificate;
        if (certDer == null) {
            return false;
        }
        try {
            certificate = new X509Certificate(certDer);
        }
        catch (CertificateException ex) {
            logger.error("decode certificate", (Throwable)ex);
            return false;
        }
        Name issuerDN = (Name)certificate.getIssuerDN();
        Name subjectDN = (Name)certificate.getSubjectDN();
        BigInteger serialNumber = certificate.getSerialNumber();
        INTEGER asn1Integer = new INTEGER(serialNumber);
        try {
            serial = new ASN1((ASN1Object)asn1Integer).toByteArray();
        }
        catch (CodingException ex) {
            logger.error("decode certificate", (Throwable)ex);
            return false;
        }
        Session session = null;
        boolean logedin = false;
        try {
            session = token.openSession(true, true, null, null);
            if (this.password != null) {
                session.login(true, this.password);
                logedin = true;
            }
            char[] label = "Moldova".toCharArray();
            Date date = new Date();
            X509PublicKeyCertificate certificateTemplate = new X509PublicKeyCertificate();
            certificateTemplate.getToken().setBooleanValue(Boolean.valueOf(true));
            certificateTemplate.getId().setByteArrayValue(newid);
            certificateTemplate.getLabel().setCharArrayValue(label);
            certificateTemplate.getStartDate().setDateValue(date);
            certificateTemplate.getValue().setByteArrayValue(certDer);
            certificateTemplate.getSerialNumber().setByteArrayValue(serial);
            certificateTemplate.getIssuer().setByteArrayValue(issuerDN.getEncoded());
            certificateTemplate.getSubject().setByteArrayValue(subjectDN.getEncoded());
            Object obj = session.createObject((Object)certificateTemplate);
            if (obj != null) {
                boolean bl = true;
                return bl;
            }
        }
        finally {
            if (logedin) {
                try {
                    session.logout();
                }
                catch (Exception ex) {
                    logger.error("", (Throwable)ex);
                }
            }
            if (session != null) {
                try {
                    session.closeSession();
                }
                catch (Exception ex) {
                    logger.error("", (Throwable)ex);
                }
            }
        }
        return false;
    }
}

