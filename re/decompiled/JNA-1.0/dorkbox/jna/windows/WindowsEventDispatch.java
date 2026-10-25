/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.sun.jna.Callback
 *  com.sun.jna.WString
 *  com.sun.jna.platform.win32.WinDef$HWND
 *  com.sun.jna.platform.win32.WinDef$LPARAM
 *  com.sun.jna.platform.win32.WinDef$LRESULT
 *  com.sun.jna.platform.win32.WinDef$WPARAM
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package dorkbox.jna.windows;

import com.sun.jna.Callback;
import com.sun.jna.WString;
import com.sun.jna.platform.win32.WinDef;
import dorkbox.jna.windows.GetLastErrorException;
import dorkbox.jna.windows.Listener;
import dorkbox.jna.windows.MSG;
import dorkbox.jna.windows.User32;
import dorkbox.jna.windows.WNDPROC;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicInteger;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class WindowsEventDispatch
implements Runnable {
    private static final Logger logger = LoggerFactory.getLogger(WindowsEventDispatch.class);
    private static final String NAME = "WindowsEventDispatch_";
    private static final AtomicInteger COUNT = new AtomicInteger(0);
    public static final int WM_TASKBARCREATED = User32.User32.RegisterWindowMessage(new WString("TaskbarCreated"));
    public static final int WM_COMMAND = 273;
    public static final int WM_SHELLNOTIFY = 1025;
    public static final int WM_MEASUREITEM = 44;
    public static final int WM_DRAWITEM = 43;
    public static final int MF_POPUP = 16;
    private final String name = "WindowsEventDispatch_" + COUNT.getAndIncrement();
    private final Map<Integer, List<Listener>> messageIDs = new HashMap<Integer, List<Listener>>();
    private final Object lock = new Object();
    private Thread dispatchThread;
    private WNDPROC WndProc;
    private volatile WinDef.HWND hWnd;

    private WindowsEventDispatch() {
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    public static WindowsEventDispatch start() {
        WindowsEventDispatch edt = new WindowsEventDispatch();
        Object object = edt.lock;
        synchronized (object) {
            edt.start_();
            try {
                edt.lock.wait();
            }
            catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        }
        return edt;
    }

    public WinDef.HWND get() {
        return this.hWnd;
    }

    private void start_() {
        this.dispatchThread = new Thread(this, this.name);
        this.dispatchThread.start();
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    public void stop() {
        Object object = this.lock;
        synchronized (object) {
            if (this.hWnd != null) {
                User32.User32.PostMessage(this.hWnd, 18, new WinDef.WPARAM(0L), new WinDef.LPARAM(0L));
                try {
                    if (!Thread.currentThread().equals(this.dispatchThread)) {
                        this.dispatchThread.join();
                    }
                }
                catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
            }
        }
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    public void addListener(int messageId, Listener listener) {
        Map<Integer, List<Listener>> map = this.messageIDs;
        synchronized (map) {
            List<Listener> listeners = this.messageIDs.get(messageId);
            if (listeners == null) {
                listeners = new ArrayList<Listener>();
                this.messageIDs.put(messageId, listeners);
            }
            listeners.add(listener);
        }
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    public void removeListener(Listener listener) {
        Map<Integer, List<Listener>> map = this.messageIDs;
        synchronized (map) {
            for (Map.Entry<Integer, List<Listener>> entry : this.messageIDs.entrySet()) {
                List<Listener> value = entry.getValue();
                if (!value.remove(listener)) continue;
                return;
            }
        }
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    @Override
    public void run() {
        this.WndProc = new WNDPROC(){

            /*
             * WARNING - Removed try catching itself - possible behaviour change.
             */
            @Override
            public WinDef.LRESULT callback(WinDef.HWND hWnd, int msg, WinDef.WPARAM wParam, WinDef.LPARAM lParam) {
                ArrayList listeners = null;
                Map map = WindowsEventDispatch.this.messageIDs;
                synchronized (map) {
                    listeners = (ArrayList)WindowsEventDispatch.this.messageIDs.get(msg);
                    if (listeners != null) {
                        listeners = new ArrayList(listeners);
                    }
                }
                if (listeners != null) {
                    for (Listener listener : listeners) {
                        if (listener == null) continue;
                        try {
                            listener.run(hWnd, wParam, lParam);
                        }
                        catch (Exception e) {
                            logger.error("Error during listener execution.", (Throwable)e);
                        }
                    }
                }
                return User32.User32.DefWindowProc(hWnd, msg, wParam, lParam);
            }
        };
        this.hWnd = User32.User32.CreateWindowEx(0, "STATIC", this.name, 0, 0, 0, 0, 0, null, null, null, null);
        if (this.hWnd == null) {
            throw new GetLastErrorException();
        }
        User32.User32.SetWindowLong(this.hWnd, -4, (Callback)this.WndProc);
        Object object = this.lock;
        synchronized (object) {
            this.lock.notifyAll();
        }
        MSG msg = new MSG();
        while (User32.User32.GetMessage(msg, null, 0, 0)) {
            User32.User32.TranslateMessage(msg);
            User32.User32.DispatchMessage(msg);
        }
        if (this.hWnd != null) {
            if (!User32.User32.DestroyWindow(this.hWnd)) {
                throw new GetLastErrorException();
            }
            this.hWnd = null;
        }
    }
}

