/*
 * Decompiled with CFR 0.152.
 */
package md.cts.moldsign.clientcardmanager.models;

import java.awt.Component;
import javax.swing.ImageIcon;
import javax.swing.JLabel;
import javax.swing.JTable;
import javax.swing.table.DefaultTableCellRenderer;

public class ImageRenderer
extends DefaultTableCellRenderer {
    private final JLabel lbl = new JLabel();

    @Override
    public Component getTableCellRendererComponent(JTable table, Object value, boolean isSelected, boolean hasFocus, int row, int column) {
        this.lbl.setText("");
        this.lbl.setIcon((ImageIcon)value);
        return this.lbl;
    }
}

