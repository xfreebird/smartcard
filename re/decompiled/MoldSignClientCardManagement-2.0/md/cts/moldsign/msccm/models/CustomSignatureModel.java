/*
 * Decompiled with CFR 0.152.
 */
package md.cts.moldsign.msccm.models;

import java.util.Iterator;
import java.util.List;
import javax.swing.event.TreeModelListener;
import javax.swing.tree.TreeModel;
import javax.swing.tree.TreePath;
import md.cts.moldsign.transferobjects.models.XAdES.XAdESSignatureModel;

public class CustomSignatureModel
implements TreeModel {
    private List<XAdESSignatureModel> signatures;

    public CustomSignatureModel() {
    }

    public CustomSignatureModel(List<XAdESSignatureModel> signatures) {
        this.signatures = signatures;
    }

    @Override
    public Object getRoot() {
        return "Signatures";
    }

    @Override
    public Object getChild(Object parent, int index) {
        List<XAdESSignatureModel> counterSig;
        if (parent instanceof XAdESSignatureModel) {
            XAdESSignatureModel sigModel = (XAdESSignatureModel)parent;
            counterSig = sigModel.getCounterSignatures();
        } else {
            counterSig = this.signatures;
        }
        return counterSig.get(index);
    }

    @Override
    public int getChildCount(Object parent) {
        if (parent instanceof XAdESSignatureModel) {
            XAdESSignatureModel sig = (XAdESSignatureModel)parent;
            if (sig.getCounterSignatures() != null) {
                return sig.getCounterSignatures().size();
            }
        } else {
            return this.signatures.size();
        }
        return 0;
    }

    public XAdESSignatureModel getParent(Object node) {
        XAdESSignatureModel result;
        block1: {
            XAdESSignatureModel model;
            result = null;
            if (!(node instanceof XAdESSignatureModel)) break block1;
            XAdESSignatureModel signature = (XAdESSignatureModel)node;
            Iterator<XAdESSignatureModel> iterator = this.signatures.iterator();
            while (iterator.hasNext() && (result = this.getParent(signature, model = iterator.next())) == null) {
            }
        }
        return result;
    }

    private XAdESSignatureModel getParent(XAdESSignatureModel child, XAdESSignatureModel parrentSearch) {
        XAdESSignatureModel result = null;
        if (parrentSearch.getCounterSignatures() == null) {
            return null;
        }
        List<XAdESSignatureModel> counterSignatures = parrentSearch.getCounterSignatures();
        for (XAdESSignatureModel sig : counterSignatures) {
            if (sig.equals(child)) {
                result = parrentSearch;
                break;
            }
            result = this.getParent(child, sig);
            if (result == null) continue;
            break;
        }
        return result;
    }

    @Override
    public boolean isLeaf(Object node) {
        if (node instanceof XAdESSignatureModel) {
            XAdESSignatureModel sig = (XAdESSignatureModel)node;
            if (sig.getCounterSignatures() != null) {
                return sig.getCounterSignatures().isEmpty();
            }
            return true;
        }
        return this.signatures == null || this.signatures.isEmpty();
    }

    @Override
    public void valueForPathChanged(TreePath path, Object newValue) {
    }

    @Override
    public int getIndexOfChild(Object parent, Object child) {
        XAdESSignatureModel parentModel = (XAdESSignatureModel)parent;
        List<XAdESSignatureModel> signatures = parentModel.getCounterSignatures();
        for (int i = 0; i < signatures.size(); ++i) {
            XAdESSignatureModel childModel = signatures.get(i);
            if (!childModel.equals(child)) continue;
            return i;
        }
        return 0;
    }

    @Override
    public void addTreeModelListener(TreeModelListener l) {
    }

    @Override
    public void removeTreeModelListener(TreeModelListener l) {
    }

    public List<XAdESSignatureModel> getSignatures() {
        return this.signatures;
    }

    public void setSignatures(List<XAdESSignatureModel> signatures) {
        this.signatures = signatures;
    }

    public boolean removeSignature(String signatureReference) {
        return this.removeSignature(this.signatures, signatureReference);
    }

    private boolean removeSignature(List<XAdESSignatureModel> list, String signatureReference) {
        for (XAdESSignatureModel signature : list) {
            if (signature.getId().equals(signatureReference)) {
                list.remove(signature);
                return true;
            }
            if (signature.getCounterSignatures() == null || signature.getCounterSignatures().isEmpty()) continue;
            return this.removeSignature(signature.getCounterSignatures(), signatureReference);
        }
        return false;
    }
}

