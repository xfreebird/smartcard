/*
 * Decompiled with CFR 0.152.
 */
package dorkbox.jna.rendering;

import dorkbox.jna.rendering.ProviderType;
import dorkbox.jna.rendering.Renderer;

class DefaultProvider
implements Renderer {
    DefaultProvider() {
    }

    @Override
    public boolean isSupported() {
        return true;
    }

    @Override
    public ProviderType getType() {
        return ProviderType.NONE;
    }

    @Override
    public boolean alreadyRunning() {
        return false;
    }

    @Override
    public boolean isEventThread() {
        return false;
    }

    @Override
    public int getGtkVersion() {
        return 0;
    }

    @Override
    public boolean dispatch(Runnable runnable) {
        return false;
    }
}

