/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.sun.jna.Pointer
 */
package dorkbox.jna.macos.cocoa;

import com.sun.jna.Pointer;
import dorkbox.jna.macos.cocoa.NSData;
import dorkbox.jna.macos.cocoa.NSObject;
import dorkbox.jna.macos.cocoa.NSString;
import dorkbox.jna.macos.foundation.ObjectiveC;
import java.awt.image.BufferedImage;
import java.awt.image.RenderedImage;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.IOException;
import javax.imageio.ImageIO;

public class NSImage
extends NSObject {
    private static final Pointer objectClass = ObjectiveC.objc_lookUpClass("NSImage");
    private static final Pointer initWithContentsOfFile = ObjectiveC.sel_getUid("initWithContentsOfFile:");
    private static final Pointer initWithData = ObjectiveC.sel_getUid("initWithData:");

    public NSImage(NSData data) {
        super(ObjectiveC.class_createInstance(objectClass, 0));
        ObjectiveC.objc_msgSend(this, initWithData, new Object[]{data});
    }

    public NSImage(BufferedImage image) throws IOException {
        this(NSImage.toBytes(image));
    }

    public NSImage(byte[] imageBytes) {
        this(new NSData(imageBytes));
    }

    public NSImage(File file) {
        super(ObjectiveC.class_createInstance(objectClass, 0));
        ObjectiveC.objc_msgSend(this, initWithContentsOfFile, new Object[]{new NSString(file.getAbsolutePath())});
    }

    private static byte[] toBytes(BufferedImage image) throws IOException {
        ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
        ImageIO.write((RenderedImage)image, "PNG", byteArrayOutputStream);
        return byteArrayOutputStream.toByteArray();
    }
}

