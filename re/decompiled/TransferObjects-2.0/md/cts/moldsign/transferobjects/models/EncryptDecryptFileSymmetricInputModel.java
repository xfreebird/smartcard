/*
 * Decompiled with CFR 0.152.
 */
package md.cts.moldsign.transferobjects.models;

public final class EncryptDecryptFileSymmetricInputModel {
    private String filePath;
    private String saveFileTo;
    private String password;
    private String algorithm;

    public EncryptDecryptFileSymmetricInputModel() {
    }

    public EncryptDecryptFileSymmetricInputModel(String filePath, String saveFileTo, String password) {
        this.filePath = filePath;
        this.saveFileTo = saveFileTo;
        this.password = password;
    }

    public EncryptDecryptFileSymmetricInputModel(String filePath, String saveFileTo, String password, String algorithm) {
        this.filePath = filePath;
        this.saveFileTo = saveFileTo;
        this.password = password;
        this.algorithm = algorithm;
    }

    public String getFilePath() {
        return this.filePath;
    }

    public void setFilePath(String filePath) {
        this.filePath = filePath;
    }

    public String getPassword() {
        return this.password;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public String getSaveFileTo() {
        return this.saveFileTo;
    }

    public void setSaveFileTo(String saveFileTo) {
        this.saveFileTo = saveFileTo;
    }

    public String getAlgorithm() {
        return this.algorithm;
    }

    public void setAlgorithm(String algorithm) {
        this.algorithm = algorithm;
    }
}

