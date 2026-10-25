/*
 * Decompiled with CFR 0.152.
 */
package dorkbox.jna.rendering;

import dorkbox.jna.rendering.DefaultProvider;
import dorkbox.jna.rendering.ProviderType;
import dorkbox.jna.rendering.Renderer;

public class RenderProvider {
    private static Renderer provider = new DefaultProvider();

    public static void set(Renderer provider) {
        RenderProvider.provider = provider;
    }

    public static boolean isSupported() {
        return provider.isSupported();
    }

    public static boolean isDefault() {
        return provider.getType() == ProviderType.NONE;
    }

    public static boolean isJavaFX() {
        return provider.getType() == ProviderType.JAVAFX;
    }

    public static boolean isSwt() {
        return provider.getType() == ProviderType.SWT;
    }

    public static ProviderType getType() {
        return provider.getType();
    }

    public static boolean isEventThread() {
        return provider.isEventThread();
    }

    public static int getGtkVersion() {
        return provider.getGtkVersion();
    }

    public static boolean dispatch(Runnable runnable) {
        return provider.dispatch(runnable);
    }

    public static boolean alreadyRunning() {
        return provider.alreadyRunning();
    }
}

