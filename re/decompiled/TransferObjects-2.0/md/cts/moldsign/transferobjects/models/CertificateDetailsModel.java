/*
 * Decompiled with CFR 0.152.
 */
package md.cts.moldsign.transferobjects.models;

import md.cts.moldsign.transferobjects.models.WorkResult;

public final class CertificateDetailsModel
implements WorkResult {
    private String keyName;
    private String keyTranslateName;
    private String value;
    private String description;

    public CertificateDetailsModel() {
    }

    public CertificateDetailsModel(String keyName, String keyTranslateName, String value, String description) {
        this.keyName = keyName;
        this.keyTranslateName = keyTranslateName;
        this.value = value;
        this.description = description;
    }

    public String getDescription() {
        return this.description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getKeyName() {
        return this.keyName;
    }

    public void setKeyName(String keyName) {
        this.keyName = keyName;
    }

    public String getKeyTranslateName() {
        return this.keyTranslateName;
    }

    public void setKeyTranslateName(String keyTranslateName) {
        this.keyTranslateName = keyTranslateName;
    }

    public String getValue() {
        return this.value;
    }

    public void setValue(String value) {
        this.value = value;
    }
}

