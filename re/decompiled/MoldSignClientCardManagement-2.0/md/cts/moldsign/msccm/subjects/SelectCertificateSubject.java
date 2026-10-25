/*
 * Decompiled with CFR 0.152.
 */
package md.cts.moldsign.msccm.subjects;

import md.cts.moldsign.msccm.observers.SelectCertificateObserver;

public interface SelectCertificateSubject {
    public void registerObserver(SelectCertificateObserver var1);

    public void removeObserver(SelectCertificateObserver var1);

    public void notifyObservers();
}

