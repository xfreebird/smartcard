/*
 * Decompiled with CFR 0.152.
 */
package dorkbox.urlHandler;

import dorkbox.urlHandler.BoxHandler;
import java.io.IOException;
import java.io.InputStream;
import java.io.NotSerializableException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.net.URL;
import java.net.URLConnection;

public class BoxURLConnection
extends URLConnection {
    public BoxURLConnection(URL url) {
        super(url);
    }

    public String getContainerName() {
        String spec = this.url.getPath();
        int separator = spec.indexOf(42);
        int length = spec.length();
        if (separator > 0 && separator != length) {
            if (spec.charAt(0) == '/') {
                if (spec.charAt(separator - 1) == '/') {
                    String substring = spec.substring(1, separator - 1);
                    return substring;
                }
                String substring = spec.substring(1, separator);
                return substring;
            }
            if (spec.charAt(separator - 1) == '/') {
                String substring = spec.substring(0, separator - 1);
                return substring;
            }
            String substring = spec.substring(0, separator);
            return substring;
        }
        return "";
    }

    public String getResourceName() {
        String spec = this.url.getPath();
        int separator = spec.indexOf(42);
        if (separator > -1 && separator != spec.length()) {
            if (spec.charAt(separator + 1) == '/') {
                return spec.substring(separator + 2);
            }
            return spec.substring(separator + 1);
        }
        return "";
    }

    @Override
    public void connect() throws IOException {
        this.connected = true;
    }

    @Override
    public int getContentLength() {
        return -1;
    }

    @Override
    public long getLastModified() {
        return 0L;
    }

    @Override
    public InputStream getInputStream() throws IOException {
        String path = this.url.getPath();
        int length = BoxHandler.protocolLength;
        StringBuilder stringBuilder = new StringBuilder(path.length() + length);
        stringBuilder.append("box:/");
        if (path.charAt(0) == '/') {
            stringBuilder.deleteCharAt(length - 1);
        }
        stringBuilder.append(path);
        InputStream is = this.getClass().getClassLoader().getResourceAsStream(stringBuilder.toString());
        return is;
    }

    public final Object clone() throws CloneNotSupportedException {
        throw new CloneNotSupportedException();
    }

    public final void writeObject(ObjectOutputStream out) throws IOException {
        throw new NotSerializableException();
    }

    public final void readObject(ObjectInputStream in) throws IOException {
        throw new NotSerializableException();
    }
}

