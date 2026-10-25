/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  md.cts.moldsign.transferobjects.models.WorkResult
 */
package md.cts.pkcs11.providers.workers.results;

import java.security.cert.X509Certificate;
import md.cts.moldsign.transferobjects.models.WorkResult;

public final class SignatureResult
implements WorkResult {
    private X509Certificate certificate;
    private byte[] signature;

    public SignatureResult(byte[] signature, X509Certificate certificate) {
        this.signature = signature;
        this.certificate = certificate;
    }

    public X509Certificate getCertificate() {
        return this.certificate;
    }

    public void setCertificate(X509Certificate certificate) {
        this.certificate = certificate;
    }

    public byte[] getSignature() {
        return this.signature;
    }

    public void setSignature(byte[] signature) {
        this.signature = signature;
    }
}

