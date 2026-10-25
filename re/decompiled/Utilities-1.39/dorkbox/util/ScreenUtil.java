/*
 * Decompiled with CFR 0.152.
 */
package dorkbox.util;

import java.awt.Container;
import java.awt.GraphicsConfiguration;
import java.awt.GraphicsDevice;
import java.awt.GraphicsEnvironment;
import java.awt.MouseInfo;
import java.awt.Point;
import java.awt.Rectangle;

public final class ScreenUtil {
    public static Rectangle getScreenBoundsAt(Point pos) {
        GraphicsDevice gd = ScreenUtil.getMonitorAtLocation(pos);
        Rectangle bounds = null;
        if (gd != null) {
            bounds = gd.getDefaultConfiguration().getBounds();
        }
        return bounds;
    }

    public static GraphicsDevice getMonitorAtMouseLocation() {
        Point mouseLocation = MouseInfo.getPointerInfo().getLocation();
        return ScreenUtil.getMonitorAtLocation(mouseLocation);
    }

    public static GraphicsDevice getMonitorAtLocation(Point pos) {
        GraphicsEnvironment ge = GraphicsEnvironment.getLocalGraphicsEnvironment();
        GraphicsDevice[] screenDevices = ge.getScreenDevices();
        GraphicsDevice device = null;
        for (GraphicsDevice device1 : screenDevices) {
            GraphicsConfiguration gc = device1.getDefaultConfiguration();
            Rectangle screenBounds = gc.getBounds();
            if (!screenBounds.contains(pos)) continue;
            device = device1;
            break;
        }
        if (device == null) {
            device = ge.getDefaultScreenDevice();
        }
        return device;
    }

    public static int getMonitorNumberAtMouseLocation() {
        Point mouseLocation = MouseInfo.getPointerInfo().getLocation();
        return ScreenUtil.getMonitorNumberAtLocation(mouseLocation);
    }

    public static int getMonitorNumberAtLocation(Point pos) {
        GraphicsEnvironment ge = GraphicsEnvironment.getLocalGraphicsEnvironment();
        GraphicsDevice[] screenDevices = ge.getScreenDevices();
        for (int i = 0; i < screenDevices.length; ++i) {
            GraphicsDevice device1 = screenDevices[i];
            GraphicsConfiguration gc = device1.getDefaultConfiguration();
            Rectangle screenBounds = gc.getBounds();
            if (!screenBounds.contains(pos)) continue;
            return i;
        }
        return 0;
    }

    public static void showOnSameScreenAsMouse_Center(Container frame) {
        Point mouseLocation = MouseInfo.getPointerInfo().getLocation();
        GraphicsDevice monitorAtMouse = ScreenUtil.getMonitorAtLocation(mouseLocation);
        Rectangle bounds = monitorAtMouse.getDefaultConfiguration().getBounds();
        frame.setLocation(bounds.x + bounds.width / 2 - frame.getWidth() / 2, bounds.y + bounds.height / 2 - frame.getHeight() / 2);
    }

    public static void showOnSameScreenAsMouse(Container frame) {
        Point mouseLocation = MouseInfo.getPointerInfo().getLocation();
        GraphicsDevice monitorAtMouse = ScreenUtil.getMonitorAtLocation(mouseLocation);
        Rectangle bounds = monitorAtMouse.getDefaultConfiguration().getBounds();
        frame.setLocation(bounds.x, bounds.y);
    }

    private ScreenUtil() {
    }
}

