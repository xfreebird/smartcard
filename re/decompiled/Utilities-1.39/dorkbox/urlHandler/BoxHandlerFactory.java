/*
 * Decompiled with CFR 0.152.
 */
package dorkbox.urlHandler;

import dorkbox.urlHandler.BoxHandler;
import java.io.IOException;
import java.io.NotSerializableException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.net.URLStreamHandler;
import java.net.URLStreamHandlerFactory;

public class BoxHandlerFactory
implements URLStreamHandlerFactory {
    private final BoxHandler transparentJar;

    public BoxHandlerFactory(BoxHandler transparentJar) {
        this.transparentJar = transparentJar;
    }

    @Override
    public URLStreamHandler createURLStreamHandler(String protocol) {
        if ("box".equals(protocol)) {
            return this.transparentJar;
        }
        return null;
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

