/*
 * Decompiled with CFR 0.152.
 */
package dorkbox.util;

import java.io.ByteArrayOutputStream;
import java.io.Closeable;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import javax.imageio.stream.ImageInputStream;

@Deprecated
public class IO {
    public static void close(Closeable closeable) {
        if (closeable != null) {
            try {
                closeable.close();
            }
            catch (IOException e) {
                System.err.println("Error closing : " + closeable);
                e.printStackTrace();
            }
        }
    }

    public static void closeQuietly(Closeable closeable) {
        if (closeable != null) {
            try {
                closeable.close();
            }
            catch (IOException iOException) {
                // empty catch block
            }
        }
    }

    public static <T extends OutputStream> T copyStream(InputStream inputStream, T outputStream) throws IOException {
        int read2;
        byte[] buffer = new byte[4096];
        while ((read2 = inputStream.read(buffer)) > 0) {
            outputStream.write(buffer, 0, read2);
        }
        outputStream.flush();
        return outputStream;
    }

    public static <T extends OutputStream> T copyStream(ImageInputStream inputStream, T outputStream) throws IOException {
        return IO.copyStream(4096, inputStream, outputStream);
    }

    public static <T extends OutputStream> T copyStream(int bufferSize, ImageInputStream inputStream, T outputStream) throws IOException {
        int read2;
        byte[] buffer = new byte[bufferSize];
        while ((read2 = inputStream.read(buffer)) > 0) {
            outputStream.write(buffer, 0, read2);
        }
        outputStream.flush();
        return outputStream;
    }

    public static ByteArrayOutputStream copyStream(InputStream inputStream) throws IOException {
        int read2;
        ByteArrayOutputStream outputStream = new ByteArrayOutputStream(4096);
        byte[] buffer = new byte[4096];
        while ((read2 = inputStream.read(buffer)) > 0) {
            outputStream.write(buffer, 0, read2);
        }
        outputStream.flush();
        return outputStream;
    }

    public static ByteArrayOutputStream copyStream(ImageInputStream inputStream) throws IOException {
        int read2;
        ByteArrayOutputStream outputStream = new ByteArrayOutputStream(4096);
        byte[] buffer = new byte[4096];
        while ((read2 = inputStream.read(buffer)) > 0) {
            outputStream.write(buffer, 0, read2);
        }
        outputStream.flush();
        return outputStream;
    }
}

