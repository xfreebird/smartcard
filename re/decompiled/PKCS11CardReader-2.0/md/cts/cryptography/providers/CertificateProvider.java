/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  md.cts.moldsign.transferobjects.models.CertificateModel
 */
package md.cts.cryptography.providers;

import java.util.Collection;
import md.cts.moldsign.transferobjects.models.CertificateModel;
import md.cts.pkcs11.cards.exceptions.OperationFailedException;

public interface CertificateProvider {
    public String getId();

    public Collection<CertificateModel> getCertificates(boolean var1);

    public void refreshCertificates() throws OperationFailedException;
}

