/*
 * Decompiled with CFR 0.152.
 */
package md.cts.pkcs11.providers.workers.signatures;

import java.security.Key;
import java.security.PublicKey;
import java.security.cert.X509Certificate;
import java.util.List;
import javax.xml.crypto.AlgorithmMethod;
import javax.xml.crypto.KeySelector;
import javax.xml.crypto.KeySelectorException;
import javax.xml.crypto.KeySelectorResult;
import javax.xml.crypto.XMLCryptoContext;
import javax.xml.crypto.XMLStructure;
import javax.xml.crypto.dsig.SignatureMethod;
import javax.xml.crypto.dsig.keyinfo.KeyInfo;
import javax.xml.crypto.dsig.keyinfo.X509Data;

public final class KeyValueKeySelector
extends KeySelector {
    static boolean algEquals(String algURI, String algName) {
        if (algName.equalsIgnoreCase("DSA") && algURI.equalsIgnoreCase("http://www.w3.org/2000/09/xmldsig#dsa-sha1")) {
            return true;
        }
        if (algName.equalsIgnoreCase("RSA") && algURI.equalsIgnoreCase("http://www.w3.org/2000/09/xmldsig#rsa-sha1")) {
            return true;
        }
        if (algName.equalsIgnoreCase("RSA") && algURI.equals("http://www.w3.org/2001/04/xmldsig-more#rsa-sha256")) {
            return true;
        }
        return algName.equalsIgnoreCase("ECDSA") && algURI.equalsIgnoreCase("http://www.w3.org/2001/04/xmldsig-more#ecdsa-sha1");
    }

    @Override
    public KeySelectorResult select(KeyInfo keyInfo, KeySelector.Purpose purpose, AlgorithmMethod method, XMLCryptoContext context) throws KeySelectorException {
        if (keyInfo == null) {
            throw new KeySelectorException("Null KeyInfo object!");
        }
        SignatureMethod sm = (SignatureMethod)method;
        List<XMLStructure> list = keyInfo.getContent();
        for (XMLStructure xmlStructure : list) {
            if (!(xmlStructure instanceof X509Data)) continue;
            List<?> x509datalist = ((X509Data)xmlStructure).getContent();
            for (Object o : x509datalist) {
                if (!(o instanceof X509Certificate)) continue;
                PublicKey pk = ((X509Certificate)o).getPublicKey();
                if (!KeyValueKeySelector.algEquals(sm.getAlgorithm(), pk.getAlgorithm())) continue;
                return new SimpleKeySelectorResult(pk);
            }
        }
        throw new KeySelectorException("No KeyValue element found!");
    }

    private static class SimpleKeySelectorResult
    implements KeySelectorResult {
        private final PublicKey pk;

        SimpleKeySelectorResult(PublicKey pk) {
            this.pk = pk;
        }

        @Override
        public Key getKey() {
            return this.pk;
        }
    }
}

