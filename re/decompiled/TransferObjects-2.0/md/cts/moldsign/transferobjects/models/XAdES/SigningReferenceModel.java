/*
 * Decompiled with CFR 0.152.
 */
package md.cts.moldsign.transferobjects.models.XAdES;

public final class SigningReferenceModel {
    private String reference;
    private String digest;
    private String path;

    public SigningReferenceModel() {
    }

    public SigningReferenceModel(String reference, String digest) {
        this.reference = reference;
        this.digest = digest;
    }

    public String getDigest() {
        return this.digest;
    }

    public void setDigest(String digest) {
        this.digest = digest;
    }

    public String getReference() {
        return this.reference;
    }

    public void setReference(String reference) {
        this.reference = reference;
    }

    public String getPath() {
        return this.path;
    }

    public void setPath(String path) {
        this.path = path;
    }
}

