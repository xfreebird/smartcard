/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  iaik.xml.crypto.dsig.DigestMethodImpl
 *  iaik.xml.crypto.xades.impl.dom.properties.CertIDImpl
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.pkcs11.providers.workers.signatures;

import iaik.xml.crypto.dsig.DigestMethodImpl;
import iaik.xml.crypto.xades.impl.dom.properties.CertIDImpl;
import java.security.cert.X509Certificate;
import javax.xml.crypto.MarshalException;
import javax.xml.crypto.dom.DOMCryptoContext;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

public final class SigWrapHack
extends CertIDImpl {
    private static final Logger logger = LoggerFactory.getLogger(SigWrapHack.class);

    public SigWrapHack(X509Certificate x509Certificate, DigestMethodImpl digestMethod) {
        super(null, x509Certificate, digestMethod);
    }

    public Node marshal(DOMCryptoContext var1, Node var2, Node var3) throws MarshalException {
        Node node0 = super.marshal(var1, var2, var3);
        logger.info("marshal={}", (Object)node0.getLocalName());
        NodeList nodelist1 = node0.getChildNodes();
        for (int i = 0; i < nodelist1.getLength(); ++i) {
            Node node1 = nodelist1.item(i);
            if (!"IssuerSerial".equals(node1.getLocalName())) continue;
            NodeList nodelist2 = node1.getChildNodes();
            for (int j = 0; j < nodelist2.getLength(); ++j) {
                Node node2 = nodelist2.item(j);
                if (!"X509IssuerName".equals(node2.getLocalName())) continue;
                String x = node2.getTextContent();
                logger.info("x={}", (Object)x);
                x = x.replace("organizationIdentifier=", "2.5.4.97=");
                logger.info("x={}", (Object)x);
                node2.setTextContent(x);
            }
        }
        return node0;
    }
}

