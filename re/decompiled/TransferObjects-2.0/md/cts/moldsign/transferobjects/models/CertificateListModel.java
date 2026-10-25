/*
 * Decompiled with CFR 0.152.
 */
package md.cts.moldsign.transferobjects.models;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import md.cts.moldsign.transferobjects.models.CertificateModel;
import md.cts.moldsign.transferobjects.models.WorkResult;

public final class CertificateListModel
implements WorkResult {
    private List<CertificateModel> certificateModel;

    public CertificateListModel() {
        this.certificateModel = new ArrayList<CertificateModel>();
    }

    public CertificateListModel(Collection<CertificateModel> certificates) {
        this.certificateModel = new ArrayList<CertificateModel>(certificates);
    }

    public List<CertificateModel> getCertificateModel() {
        return this.certificateModel;
    }

    public void setCertificateModel(List<CertificateModel> certificateModel) {
        this.certificateModel = certificateModel;
    }
}

