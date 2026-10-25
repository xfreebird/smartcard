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
import md.cts.moldsign.msccm.panels.DragDropNotify;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class VerifyDropListener
implements DropTargetListener {
    private static final Logger logger = LoggerFactory.getLogger(VerifyDropListener.class);
    private final DragDropNotify listiner;

    public VerifyDropListener(DragDropNotify listiner) {
        this.listiner = listiner;
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

    @Override
    public void drop(DropTargetDropEvent dtde) {
        try {
            dtde.acceptDrop(1);
            Transferable transferable = dtde.getTransferable();
            Object transfer = transferable.getTransferData(DataFlavor.javaFileListFlavor);
            if (transfer instanceof List) {
                List droppedFiles = (List)transfer;
                for (File file : droppedFiles) {
                    this.listiner.onAddedFile(file);
                }
            }
        }
        catch (Exception ex) {
            logger.error("", (Throwable)ex);
        }
        dtde.dropComplete(true);
    }
}

