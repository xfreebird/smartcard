/*
 * Decompiled with CFR 0.152.
 */
package md.cts.moldsign.transferobjects.models.XAdES;

import java.util.Date;
import md.cts.moldsign.transferobjects.models.CertificateModel;

public final class TimeStampModel {
    private Date time;
    private CertificateModel signer;

    public CertificateModel getSigner() {
        return this.signer;
    }

    public void setSigner(CertificateModel signer) {
        this.signer = signer;
    }

    public Date getTime() {
        return this.time;
    }

    public void setTime(Date time) {
        this.time = time;
    }
}

