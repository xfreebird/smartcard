/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  dorkbox.os.OS
 */
package dorkbox.util;

import dorkbox.os.OS;
import dorkbox.util.LocationResolver;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.security.AccessController;
import java.security.PrivilegedAction;

public class NativeLoader {
    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    public static File extractLibrary(String sourceFileName, String destinationDirectory, String destinationName, String version) throws IOException {
        try {
            String suffix = OS.INSTANCE.getType().getLibraryNames()[0];
            String outputFileName = version == null ? destinationName + suffix : destinationName + "." + version + suffix;
            File file = new File(destinationDirectory, outputFileName);
            if (!file.canRead() || file.length() == 0L || !file.canExecute()) {
                InputStream inputStream = LocationResolver.getResourceAsStream(sourceFileName);
                FileOutputStream outStream = null;
                try {
                    int read2;
                    outStream = new FileOutputStream(file);
                    byte[] buffer = new byte[4096];
                    while ((read2 = inputStream.read(buffer)) > 0) {
                        ((OutputStream)outStream).write(buffer, 0, read2);
                    }
                    outStream.flush();
                    ((OutputStream)outStream).close();
                    outStream = null;
                }
                finally {
                    try {
                        inputStream.close();
                    }
                    catch (Exception exception) {}
                    try {
                        if (outStream != null) {
                            ((OutputStream)outStream).close();
                        }
                    }
                    catch (Exception exception) {}
                }
            }
            return file;
        }
        catch (Exception e) {
            throw new IOException("Error extracting library: " + sourceFileName, e);
        }
    }

    public static void loadLibrary(final File file) {
        AccessController.doPrivileged(new PrivilegedAction<Object>(){

            @Override
            public Object run() {
                System.load(file.getAbsolutePath());
                return null;
            }
        });
    }

    private NativeLoader() {
    }
}

