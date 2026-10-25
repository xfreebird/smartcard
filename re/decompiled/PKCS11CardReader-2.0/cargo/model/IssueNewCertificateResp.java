/*
 * Decompiled with CFR 0.152.
 */
package cargo.model;

public final class IssueNewCertificateResp {
    public final String key_id;
    public final String client_nonce;
    public final String new_certificate;

    public IssueNewCertificateResp(String key_id, String client_nonce, String new_certificate, String issuer_certificate) {
        this.key_id = key_id;
        this.client_nonce = client_nonce;
        this.new_certificate = new_certificate;
    }

    public String toString() {
        return "key_id: " + this.key_id + "\nclient_nonce: " + this.client_nonce + "\nnew_certificate: " + this.new_certificate + "\n";
    }
}

