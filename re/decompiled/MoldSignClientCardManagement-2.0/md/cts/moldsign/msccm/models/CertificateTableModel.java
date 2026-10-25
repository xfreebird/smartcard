/*
 * Decompiled with CFR 0.152.
 */
package md.cts.moldsign.msccm.models;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import javax.swing.table.AbstractTableModel;
import md.cts.moldsign.transferobjects.models.CertificateDetailsModel;

public class CertificateTableModel
extends AbstractTableModel {
    private final String[] columnNames = new String[]{"Key", "Value"};
    private final List<CertificateDetailsModel> certDetails;

    public CertificateTableModel(Collection<CertificateDetailsModel> certs) {
        this.certDetails = new ArrayList<CertificateDetailsModel>(certs);
    }

    public void setCerts(Collection<CertificateDetailsModel> certs) {
        this.certDetails.clear();
        this.certDetails.addAll(certs);
        this.fireTableDataChanged();
    }

    @Override
    public int getColumnCount() {
        return this.columnNames.length;
    }

    @Override
    public int getRowCount() {
        return this.certDetails.size();
    }

    @Override
    public String getColumnName(int col) {
        return this.columnNames[col];
    }

    @Override
    public Object getValueAt(int row, int col) {
        CertificateDetailsModel cert = this.certDetails.get(row);
        return switch (col) {
            case 0 -> cert.getKeyName();
            case 1 -> cert.getValue();
            default -> null;
        };
    }

    public CertificateDetailsModel getCertificateAt(int selectedRow) {
        return this.certDetails.get(selectedRow);
    }

    public boolean isEmpty() {
        return this.certDetails.isEmpty();
    }
}

