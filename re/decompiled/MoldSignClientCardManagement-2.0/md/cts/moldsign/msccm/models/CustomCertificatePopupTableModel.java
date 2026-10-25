/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  iaik.asn1.ObjectID
 *  iaik.asn1.structures.Name
 */
package md.cts.moldsign.msccm.models;

import iaik.asn1.ObjectID;
import iaik.asn1.structures.Name;
import java.security.Principal;
import java.text.DateFormat;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Date;
import java.util.List;
import java.util.Locale;
import javax.swing.ImageIcon;
import javax.swing.table.AbstractTableModel;
import md.cts.moldsign.transferobjects.models.CertificateModel;
import md.ghesar.Resource;

public class CustomCertificatePopupTableModel
extends AbstractTableModel {
    private final String[] columnNames = new String[]{"", "Name", "Issuer", "Validity period", "Provider"};
    private final List<CertificateModel> certs;

    public CustomCertificatePopupTableModel(Collection<CertificateModel> certs) {
        this.certs = new ArrayList<CertificateModel>(certs);
    }

    public static String getNameFromDN(Principal p) {
        Object name = "";
        Name n = (Name)p;
        if (n != null) {
            name = n.getRDN(ObjectID.commonName);
            name = name == null || ((String)name).isEmpty() ? n.getRDN(ObjectID.organization) : (String)name + " (" + n.getRDN(ObjectID.organization) + ")";
        }
        return name;
    }

    public void setCerts(Collection<CertificateModel> certs) {
        this.certs.clear();
        this.certs.addAll(certs);
        this.certs.sort((o1, o2) -> {
            if ("MSCSP".equals(o1.getProviderId())) {
                return 1;
            }
            if ("MSCSP".equals(o2.getProviderId())) {
                return -1;
            }
            return 0;
        });
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
        CertificateModel cert = this.certs.get(row);
        String retVal = switch (col) {
            case 0 -> {
                if (cert.isPrivateKeyPresent()) {
                    yield new ImageIcon(Resource.getImage("/icon_certificate.png"));
                }
                yield new ImageIcon(Resource.getImage("/icon_certificate_no_key.png"));
            }
            case 1 -> CustomCertificatePopupTableModel.getNameFromDN(cert.getCertificate().getSubjectDN());
            case 2 -> CustomCertificatePopupTableModel.getNameFromDN(cert.getCertificate().getIssuerDN());
            case 3 -> this.formatDate(cert.getCertificate().getNotBefore()) + " - " + this.formatDate(cert.getCertificate().getNotAfter());
            case 4 -> cert.getProviderId();
            default -> null;
        };
        return retVal;
    }

    private String formatDate(Date d) {
        DateFormat df = DateFormat.getDateTimeInstance(2, 2, Locale.getDefault());
        return df.format(d);
    }

    public CertificateModel getCertificateAt(int selectedRow) {
        return this.certs.get(selectedRow);
    }

    public boolean isEmpty() {
        return this.certs.isEmpty();
    }
}

