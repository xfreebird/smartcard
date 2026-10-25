/*
 * Decompiled with CFR 0.152.
 */
package md.cts.moldsign.msccm.models;

import java.util.List;
import javax.swing.event.TreeModelListener;
import javax.swing.tree.TreeModel;
import javax.swing.tree.TreePath;
import md.cts.moldsign.transferobjects.models.CertificateModel;

public class CustomTreeModel
implements TreeModel {
    private final List<CertificateModel> certificates;

    public CustomTreeModel(List<CertificateModel> certificates) {
        this.certificates = certificates;
    }

    @Override
    public Object getRoot() {
        return this.certificates.get(this.certificates.size() - 1);
    }

    @Override
    public Object getChild(Object parent, int index) {
        for (int i = 0; i < this.certificates.size(); ++i) {
            CertificateModel object = this.certificates.get(i);
            if (!parent.equals(object)) continue;
            return this.certificates.get(i - 1);
        }
        return this.certificates.get(0);
    }

    @Override
    public int getChildCount(Object parent) {
        return 1;
    }

    @Override
    public boolean isLeaf(Object node) {
        return node.equals(this.certificates.get(0));
    }

    @Override
    public void valueForPathChanged(TreePath path, Object newValue) {
    }

    @Override
    public int getIndexOfChild(Object parent, Object child) {
        return 1;
    }

    @Override
    public void addTreeModelListener(TreeModelListener l) {
    }

    @Override
    public void removeTreeModelListener(TreeModelListener l) {
    }
}

