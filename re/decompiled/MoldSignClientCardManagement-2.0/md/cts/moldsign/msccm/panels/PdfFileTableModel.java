/*
 * Decompiled with CFR 0.152.
 */
package md.cts.moldsign.msccm.panels;

import java.io.File;
import java.util.ArrayList;
import java.util.List;
import javax.swing.table.AbstractTableModel;

public final class PdfFileTableModel
extends AbstractTableModel {
    private final List<String> items = new ArrayList<String>();
    private final String[] columnNames;

    PdfFileTableModel(String[] columnNames) {
        this.columnNames = columnNames;
    }

    public void add(String item) {
        this.items.add(item);
        int row = this.items.indexOf(item);
        this.fireTableRowsInserted(row, row);
    }

    public String getRow(int row) {
        return this.items.get(row);
    }

    public void clear() {
        this.items.clear();
        this.fireTableDataChanged();
    }

    public boolean contains(String x) {
        return this.items.contains(x);
    }

    @Override
    public int getRowCount() {
        return this.items.size();
    }

    @Override
    public int getColumnCount() {
        return this.columnNames.length;
    }

    @Override
    public String getColumnName(int column) {
        return this.columnNames[column];
    }

    @Override
    public Object getValueAt(int rowIndex, int columnIndex) {
        String item = this.items.get(rowIndex);
        File file = new File(item);
        return switch (columnIndex) {
            case 0 -> file.getName();
            case 1 -> file.getParent();
            default -> null;
        };
    }
}

