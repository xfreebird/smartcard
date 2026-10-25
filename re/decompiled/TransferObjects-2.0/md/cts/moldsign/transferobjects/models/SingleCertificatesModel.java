/*
 * Decompiled with CFR 0.152.
 */
package md.cts.moldsign.transferobjects.models;

import md.cts.moldsign.transferobjects.models.CertificateModel;
import md.cts.moldsign.transferobjects.models.WorkResult;

public final class SingleCertificatesModel
implements WorkResult {
    private CertificateModel certificateModel;

    public SingleCertificatesModel() {
    }

    public SingleCertificatesModel(CertificateModel certificateModel) {
        this.certificateModel = certificateModel;
    }

    public CertificateModel getCertificateModel() {
        return this.certificateModel;
    }

    public void setCertificateModel(CertificateModel certificateModel) {
        this.certificateModel = certificateModel;
    }
}

