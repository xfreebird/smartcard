/*
 * Decompiled with CFR 0.152.
 */
package cargo.model;

import cargo.model.TokenInformation;

public final class IssueNewCertificateReq {
    public final String client_nonce;
    public final String key_id;
    private final String algorithm_new = "RSA_SHA256";
    private final String algorithm_existing = "RSA_SHA256";
    private final String existing_certificate;
    private final String public_key;
    private final String signature_new;
    private final String signature_existing;
    private final TokenInformation token_info;

    public IssueNewCertificateReq(String client_nonce, String key_id, String existing_certificate, String public_key, String signature_new, String signature_existing, TokenInformation token_info) {
        this.client_nonce = client_nonce;
        this.key_id = key_id;
        this.existing_certificate = existing_certificate;
        this.public_key = public_key;
        this.signature_new = signature_new;
        this.signature_existing = signature_existing;
        this.token_info = token_info;
    }

    public String toString() {
        return "key_id: " + this.key_id + "\nclient_nonce: " + this.client_nonce + "\nexisting_certificate: " + this.existing_certificate + "\npublic_key: " + this.public_key + "\nalgorithm_new: RSA_SHA256\nsignature_new: " + this.signature_new + "\nalgorithm_existing: RSA_SHA256\nsignature_existing: " + this.signature_existing + "\n";
    }
}

