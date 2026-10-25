/*
 * Decompiled with CFR 0.152.
 */
package dorkbox.jna.rendering;

import dorkbox.jna.rendering.ProviderType;

public interface Renderer {
    public boolean isSupported();

    public ProviderType getType();

    public boolean alreadyRunning();

    public boolean isEventThread();

    public int getGtkVersion();

    public boolean dispatch(Runnable var1);
}

