/*
 * Decompiled with CFR 0.152.
 */
package md.cts.moldsign.transferobjects.models.XAdES;

import java.util.ArrayList;
import java.util.List;
import md.cts.moldsign.transferobjects.models.WorkResult;
import md.cts.moldsign.transferobjects.models.XAdES.XAdESSignatureModel;

public final class XadesSignatureModelContainer
implements WorkResult {
    private String fileLocation;
    private List<XAdESSignatureModel> signatures = new ArrayList<XAdESSignatureModel>();
    private String encodedData;

    public XadesSignatureModelContainer() {
    }

    public XadesSignatureModelContainer(List<XAdESSignatureModel> signatures) {
        this.signatures = signatures;
    }

    public List<XAdESSignatureModel> getSignatures() {
        return this.signatures;
    }

    public void setSignatures(List<XAdESSignatureModel> signatures) {
        this.signatures = signatures;
    }

    public String getFileLocation() {
        return this.fileLocation;
    }

    public void setFileLocation(String fileLocation) {
        this.fileLocation = fileLocation;
    }

    public String getEncodedData() {
        return this.encodedData;
    }

    public void setEncodedData(String encodedData) {
        this.encodedData = encodedData;
    }
}

