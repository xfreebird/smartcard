/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  iaik.x509.X509CRL
 */
package md.cts.cryptography.certificates.wrappers;

import iaik.x509.X509CRL;

public final class CRLWrapper {
    private final X509CRL crl;
    private final String uri;

    public CRLWrapper(X509CRL crl, String uri) {
        this.crl = crl;
        this.uri = uri;
    }

    public X509CRL getCrl() {
        return this.crl;
    }

    public String getUri() {
        return this.uri;
    }
}

