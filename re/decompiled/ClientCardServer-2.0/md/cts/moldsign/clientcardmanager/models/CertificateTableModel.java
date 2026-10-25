/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  iaik.asn1.ObjectID
 *  iaik.asn1.structures.Name
 *  md.ghesar.Resource
 */
package md.cts.moldsign.clientcardmanager.models;

import iaik.asn1.ObjectID;
import iaik.asn1.structures.Name;
import java.security.Principal;
import java.text.DateFormat;
import java.util.Date;
import java.util.List;
import java.util.Locale;
import javax.swing.ImageIcon;
import javax.swing.table.AbstractTableModel;
import md.cts.pkcs11.cards.certificates.CertificateFull;
import md.ghesar.Resource;

public class CertificateTableModel
extends AbstractTableModel {
    private final String[] columnNames = new String[]{"", "Name", "Issuer", "Validity period"};
    private final List<CertificateFull> certs;

    public CertificateTableModel(List<CertificateFull> certs) {
        this.certs = certs;
        this.fireTableDataChanged();
    }

    public void setCerts(List<CertificateFull> certs) {
        this.certs.clear();
        this.certs.addAll(certs);
        this.fireTableDataChanged();
    }

    @Override
    public int getColumnCount() {
        return this.columnNames.length;
    }

    @Override
    public int getRowCount() {
        return this.certs.size();
    }

    @Override
    public String getColumnName(int col) {
        return this.columnNames[col];
    }

    @Override
    public Object getValueAt(int row, int col) {
        CertificateFull cert = this.certs.get(row);
        ImageIcon retVal = switch (col) {
            case 0 -> {
                if (cert.isPrivateKeyPresent()) {
                    yield new ImageIcon(Resource.getImage((String)"/icon_certificate.png"));
                }
                yield new ImageIcon(Resource.getImage((String)"/icon_certificate_no_key.png"));
            }
            case 1 -> this.getNameFromDN(cert.getCert().getSubjectDN());
            case 2 -> this.getNameFromDN(cert.getCert().getIssuerDN());
            case 3 -> this.formatDate(cert.getCert().getNotBefore()) + " - " + this.formatDate(cert.getCert().getNotAfter());
            default -> null;
        };
        return retVal;
    }

    private String getNameFromDN(Principal p) {
        Object name = "";
        Name n = (Name)p;
        if (n != null) {
            name = n.getRDN(ObjectID.commonName);
            name = name == null || ((String)name).isEmpty() ? n.getRDN(ObjectID.organization) : (String)name + " (" + n.getRDN(ObjectID.organization) + ")";
        }
        return name;
    }

    private String formatDate(Date d) {
        DateFormat df = DateFormat.getDateTimeInstance(2, 2, Locale.getDefault());
        return df.format(d);
    }

    public CertificateFull getCertificateAt(int selectedRow) {
        return this.certs.get(selectedRow);
    }

    public boolean isEmpty() {
        return this.certs.isEmpty();
    }
}

