/*
 * Decompiled with CFR 0.152.
 */
package dorkbox.urlHandler;

import dorkbox.urlHandler.BoxURLConnection;
import java.io.IOException;
import java.io.NotSerializableException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.net.URL;
import java.net.URLConnection;
import java.net.URLStreamHandler;

public class BoxHandler
extends URLStreamHandler {
    static final char jarUrlSeperator = '*';
    static final char jarPathToken = '/';
    static final char packageToken = '.';
    static final String protocol = "box";
    static final String protocolFull = "box:/";
    static final int protocolLength = "box:/".length();

    @Override
    protected URLConnection openConnection(URL url) throws IOException {
        return new BoxURLConnection(url);
    }

    @Override
    protected String toExternalForm(URL url) {
        char jarurlseperator;
        String externalForm = super.toExternalForm(url);
        if (externalForm.indexOf(jarurlseperator = '*') == -1) {
            int length = externalForm.length();
            StringBuilder stringBuilder = new StringBuilder(length + 1);
            stringBuilder.append(externalForm);
            if (length > 1 && externalForm.charAt(length - 1) == '/') {
                stringBuilder.insert(length, jarurlseperator);
            } else {
                stringBuilder.append(jarurlseperator);
            }
            return stringBuilder.toString();
        }
        return externalForm;
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

