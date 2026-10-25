/*
 * Decompiled with CFR 0.152.
 */
package md.cts.moldsign.transferobjects.models;

import java.util.List;
import md.cts.moldsign.transferobjects.models.WorkResult;

public final class VerifySignedFileInputModel
implements WorkResult {
    private List<String> signedFiles;
    private String signature;
    private String signatureId;

    public VerifySignedFileInputModel() {
    }

    public VerifySignedFileInputModel(List<String> signedFiles, String signature, String signatureId) {
        this.signedFiles = signedFiles;
        this.signature = signature;
        this.signatureId = signatureId;
    }

    public String getSignature() {
        return this.signature;
    }

    public void setSignature(String signature) {
        this.signature = signature;
    }

    public List<String> getSignedFiles() {
        return this.signedFiles;
    }

    public void setSignedFiles(List<String> signedFiles) {
        this.signedFiles = signedFiles;
    }

    public String getSignatureId() {
        return this.signatureId;
    }

    public void setSignatureId(String signatureId) {
        this.signatureId = signatureId;
    }
}

