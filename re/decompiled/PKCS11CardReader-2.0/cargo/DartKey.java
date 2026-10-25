/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  iaik.asn1.ASN
 *  iaik.asn1.ASN1Object
 *  iaik.asn1.CodingException
 *  iaik.asn1.DerCoder
 *  iaik.asn1.OCTET_STRING
 *  iaik.asn1.ObjectID
 *  iaik.pkcs.pkcs11.objects.ECDSAPublicKey
 *  iaik.pkcs.pkcs11.objects.RSAPublicKey
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package cargo;

import cargo.DartPki;
import cargo.Rust;
import iaik.asn1.ASN;
import iaik.asn1.ASN1Object;
import iaik.asn1.CodingException;
import iaik.asn1.DerCoder;
import iaik.asn1.OCTET_STRING;
import iaik.asn1.ObjectID;
import iaik.pkcs.pkcs11.objects.ECDSAPublicKey;
import iaik.pkcs.pkcs11.objects.RSAPublicKey;
import java.io.IOException;
import java.security.PublicKey;
import java.util.Base64;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class DartKey {
    private static final Logger logger = LoggerFactory.getLogger(DartKey.class);
    private final byte[] id;
    private PublicKey pubKey;

    public DartKey(byte[] id) {
        this.id = id;
    }

    public boolean decodeRSA(RSAPublicKey key) {
        byte[] pkcsModulus = key.getModulus().getByteArrayValue();
        byte[] pkcsExponent = key.getPublicExponent().getByteArrayValue();
        this.pubKey = DartPki.rsaKeyFromBytes(pkcsModulus, pkcsExponent);
        logger.info("rsa pub key\n{}\n", (Object)this.getPubKey_b64());
        return this.pubKey != null;
    }

    public boolean decodeEC(ECDSAPublicKey key) {
        byte[] affineY;
        byte[] affineX;
        String curveName;
        block7: {
            byte[] ecPoint = key.getEcPoint().getByteArrayValue();
            byte[] ecParams = key.getEcdsaParams().getByteArrayValue();
            curveName = null;
            affineX = null;
            affineY = null;
            try {
                ASN1Object ob2;
                ASN1Object ob1 = DerCoder.decode((byte[])ecPoint);
                if (ASN.OCTET_STRING.equals((Object)ob1.getAsnType())) {
                    OCTET_STRING pub1 = (OCTET_STRING)ob1;
                    byte[] pubPoint = pub1.getWholeValue();
                    logger.info("pubPoint.length {}", (Object)pubPoint.length);
                    logger.info("pubPoint {}", (Object)Rust.bytesToHex(pubPoint));
                    int length = pubPoint.length - 1 >>> 1;
                    affineX = new byte[length];
                    System.arraycopy(pubPoint, 1, affineX, 0, length);
                    affineY = new byte[length];
                    System.arraycopy(pubPoint, 1 + length, affineY, 0, length);
                    logger.info("affineX {}", (Object)Rust.bytesToHex(affineX));
                    logger.info("affineY {}", (Object)Rust.bytesToHex(affineY));
                }
                if (!ASN.ObjectID.equals((Object)(ob2 = DerCoder.decode((byte[])ecParams)).getAsnType())) break block7;
                ObjectID id = (ObjectID)ob2;
                String oid = id.getID();
                logger.info("oid {}", (Object)oid);
                if ("1.2.840.10045.3.1.7".equals(oid)) {
                    curveName = "secp256r1";
                    break block7;
                }
                if ("1.3.132.0.34".equals(oid)) {
                    curveName = "secp384r1";
                    break block7;
                }
                if ("1.3.132.0.35".equals(oid)) {
                    curveName = "secp521r1";
                    break block7;
                }
                logger.error("unsupported curve");
                return false;
            }
            catch (CodingException | IOException ex) {
                logger.error("", ex);
                return false;
            }
        }
        if (affineX == null || affineY == null || curveName == null) {
            logger.error("unrecognised key");
            return false;
        }
        this.pubKey = DartPki.ecKeyFromBytes(affineX, affineY, curveName);
        logger.info("ec pub key\n{}\n", (Object)this.getPubKey_b64());
        return this.pubKey != null;
    }

    public PublicKey getKey() {
        return this.pubKey;
    }

    public byte[] getId() {
        return this.id;
    }

    public String getId_b64() {
        return Base64.getEncoder().encodeToString(this.id);
    }

    public byte[] getKeyBytes() {
        return this.pubKey.getEncoded();
    }

    public String getPubKey_b64() {
        byte[] der = this.pubKey.getEncoded();
        if (der == null) {
            return null;
        }
        return Base64.getEncoder().encodeToString(der);
    }
}

