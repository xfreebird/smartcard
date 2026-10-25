/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.moldsign.msccm.models;

import java.awt.datatransfer.DataFlavor;
import java.awt.datatransfer.Transferable;
import java.awt.dnd.DropTargetDragEvent;
import java.awt.dnd.DropTargetDropEvent;
import java.awt.dnd.DropTargetEvent;
import java.awt.dnd.DropTargetListener;
import java.io.File;
import java.util.List;
import javax.swing.table.DefaultTableModel;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class FileDragDropListener
implements DropTargetListener {
    private static final Logger logger = LoggerFactory.getLogger(FileDragDropListener.class);
    private final DefaultTableModel model;

    public FileDragDropListener(DefaultTableModel model) {
        this.model = model;
    }

    @Override
    public void drop(DropTargetDropEvent dtde) {
        DataFlavor[] flavors;
        dtde.acceptDrop(1);
        Transferable transferable = dtde.getTransferable();
        for (DataFlavor flavor : flavors = transferable.getTransferDataFlavors()) {
            try {
                if (!flavor.isFlavorJavaFileListType()) continue;
                Object data = transferable.getTransferData(flavor);
                List files = null;
                if (data instanceof List) {
                    files = (List)data;
                }
                if (files == null) continue;
                for (File file : files) {
                    this.model.addRow(new String[]{file.getAbsolutePath()});
                }
                this.model.fireTableDataChanged();
            }
            catch (Exception exception) {
                logger.error("", (Throwable)exception);
            }
        }
        dtde.dropComplete(true);
    }

    @Override
    public void dragEnter(DropTargetDragEvent dtde) {
    }

    @Override
    public void dragOver(DropTargetDragEvent dtde) {
    }

    @Override
    public void dropActionChanged(DropTargetDragEvent dtde) {
    }

    @Override
    public void dragExit(DropTargetEvent dte) {
    }
}

