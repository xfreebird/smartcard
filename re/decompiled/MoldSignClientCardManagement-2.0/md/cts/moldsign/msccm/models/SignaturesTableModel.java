/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.moldsign.msccm.models;

import java.io.File;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.ArrayList;
import java.util.List;
import javax.swing.table.AbstractTableModel;
import md.cts.moldsign.transferobjects.models.XAdES.SigningReferenceModel;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class SignaturesTableModel
extends AbstractTableModel {
    private static final Logger logger = LoggerFactory.getLogger(SignaturesTableModel.class);
    private static final String[] columnNames = new String[]{"File name", "File path"};
    private List<SigningReferenceModel> signingRefModel = new ArrayList<SigningReferenceModel>();

    public void clear() {
        this.signingRefModel.clear();
    }

    public void setRefs(List<SigningReferenceModel> references) {
        this.signingRefModel = references;
        this.fireTableDataChanged();
    }

    @Override
    public int getColumnCount() {
        return columnNames.length;
    }

    @Override
    public int getRowCount() {
        return this.signingRefModel.size();
    }

    @Override
    public String getColumnName(int col) {
        return columnNames[col];
    }

    @Override
    public Object getValueAt(int row, int col) {
        SigningReferenceModel ref = this.signingRefModel.get(row);
        String retVal = null;
        switch (col) {
            case 0: {
                retVal = ref.getReference();
                try {
                    File f = new File(new URI(retVal));
                    retVal = f.getName();
                }
                catch (URISyntaxException ex) {
                    logger.error("", (Throwable)ex);
                }
                break;
            }
            case 1: {
                retVal = ref.getPath();
            }
        }
        return retVal;
    }

    public SigningReferenceModel getReferenceAt(int selectedRow) {
        return this.signingRefModel.get(selectedRow);
    }
}

