/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.sun.jna.Pointer
 *  org.slf4j.LoggerFactory
 */
package dorkbox.jna.linux;

import com.sun.jna.Pointer;
import dorkbox.jna.linux.FuncCallback;
import dorkbox.jna.linux.GMainContext;
import dorkbox.jna.linux.GMainLoop;
import dorkbox.jna.linux.Glib;
import dorkbox.jna.linux.Gtk2;
import dorkbox.jna.linux.GtkLoader;
import dorkbox.jna.rendering.RenderProvider;
import java.awt.event.ActionListener;
import java.util.LinkedList;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import org.slf4j.LoggerFactory;

public class GtkEventDispatch {
    static boolean FORCE_GTK2 = false;
    static boolean PREFER_GTK3 = false;
    static boolean DEBUG = false;
    private static final LinkedList<FuncCallback> gtkCallbacks = new LinkedList();
    private static ThreadLocal<Boolean> isDispatch = new ThreadLocal<Boolean>(){

        @Override
        protected Boolean initialValue() {
            return false;
        }
    };
    private static boolean started = false;
    private static Thread gtkUpdateThread = null;
    private static GMainLoop mainloop;
    private static GMainContext context;
    private static final boolean debugEDT = false;
    private static final int TIMEOUT = 2;

    public static synchronized void startGui(boolean forceGtk2, boolean preferGkt3, final boolean debug) {
        if (!started) {
            started = true;
            FORCE_GTK2 = forceGtk2;
            PREFER_GTK3 = preferGkt3;
            DEBUG = debug;
            if (!GtkLoader.alreadyRunningGTK) {
                gtkUpdateThread = new Thread(){

                    @Override
                    public void run() {
                        Glib.GLogFunc orig = null;
                        if (debug) {
                            LoggerFactory.getLogger(GtkEventDispatch.class).debug("Running GTK Native Event Loop");
                        } else {
                            orig = Glib.g_log_set_default_handler(Glib.nullLogFunc, null);
                        }
                        if (!Gtk2.Gtk2.gtk_init_check(0)) {
                            throw new RuntimeException("Error starting GTK");
                        }
                        mainloop = Gtk2.Gtk2.g_main_loop_new(null, false);
                        context = Gtk2.Gtk2.g_main_loop_get_context(mainloop);
                        Gtk2.Gtk2.g_main_loop_run(mainloop);
                        if (orig != null) {
                            Glib.g_log_set_default_handler(orig, null);
                        }
                    }
                };
                gtkUpdateThread.setDaemon(false);
                gtkUpdateThread.setName("GTK Native Event Loop");
                gtkUpdateThread.start();
            }
        }
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     * Enabled aggressive block sorting
     * Enabled unnecessary exception pruning
     * Enabled aggressive exception aggregation
     */
    public static synchronized void waitForEventsToComplete() {
        final CountDownLatch blockUntilStarted = new CountDownLatch(1);
        GtkEventDispatch.dispatch(new Runnable(){

            @Override
            public void run() {
                blockUntilStarted.countDown();
            }
        });
        if (RenderProvider.isEventThread()) return;
        try {
            if (!blockUntilStarted.await(10L, TimeUnit.SECONDS) && DEBUG) {
                LoggerFactory.getLogger(GtkEventDispatch.class).error("Something is very wrong. The waitForEventsToComplete took longer than expected.", (Throwable)new Exception(""));
            }
            while (true) {
                Thread.sleep(100L);
                LinkedList<FuncCallback> linkedList = gtkCallbacks;
                synchronized (linkedList) {
                    if (gtkCallbacks.isEmpty()) {
                        return;
                    }
                }
            }
        }
        catch (InterruptedException e) {
            e.printStackTrace();
        }
    }

    public static void dispatchAndWait(final Runnable runnable) {
        block4: {
            Boolean isDispatch = GtkEventDispatch.isDispatch.get();
            if (isDispatch.booleanValue()) {
                runnable.run();
                return;
            }
            final CountDownLatch countDownLatch = new CountDownLatch(1);
            GtkEventDispatch.dispatch(new Runnable(){

                @Override
                public void run() {
                    try {
                        runnable.run();
                    }
                    catch (Exception e) {
                        LoggerFactory.getLogger(GtkEventDispatch.class).error("Error during GTK run loop: ", (Throwable)e);
                    }
                    finally {
                        countDownLatch.countDown();
                    }
                }
            });
            try {
                if (countDownLatch.await(2L, TimeUnit.SECONDS)) break block4;
                if (DEBUG) {
                    LoggerFactory.getLogger(GtkEventDispatch.class).error("Something is very wrong. The Event Dispatch Queue took longer than 2 seconds to complete.", (Throwable)new Exception(""));
                    break block4;
                }
                throw new RuntimeException("Something is very wrong. The Event Dispatch Queue took longer than 2 seconds to complete.");
            }
            catch (InterruptedException e) {
                LoggerFactory.getLogger(GtkEventDispatch.class).error("Error waiting for dispatch to complete.", (Throwable)new Exception(""));
            }
        }
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    public static void dispatch(final Runnable runnable) {
        if (GtkLoader.alreadyRunningGTK && RenderProvider.dispatch(runnable)) {
            return;
        }
        if (isDispatch.get().booleanValue()) {
            runnable.run();
            return;
        }
        FuncCallback callback = new FuncCallback(){

            /*
             * WARNING - Removed try catching itself - possible behaviour change.
             */
            @Override
            public int callback(Pointer data) {
                isDispatch.set(true);
                try {
                    runnable.run();
                }
                finally {
                    isDispatch.set(false);
                }
                LinkedList linkedList = gtkCallbacks;
                synchronized (linkedList) {
                    gtkCallbacks.removeFirst();
                }
                return 0;
            }
        };
        LinkedList<FuncCallback> linkedList = gtkCallbacks;
        synchronized (linkedList) {
            gtkCallbacks.offer(callback);
        }
        Gtk2.Gtk2.g_main_context_invoke(context, callback, null);
    }

    public static void proxyClick(ActionListener callback) {
        isDispatch.set(true);
        try {
            callback.actionPerformed(null);
        }
        catch (Throwable t) {
            LoggerFactory.getLogger(GtkEventDispatch.class).error("Error during GTK click callback: ", t);
        }
        isDispatch.set(false);
    }

    public static synchronized void shutdownGui() {
        GtkEventDispatch.dispatchAndWait(new Runnable(){

            @Override
            public void run() {
                if (!GtkLoader.alreadyRunningGTK) {
                    Gtk2.Gtk2.g_main_loop_quit(mainloop);
                }
                started = false;
            }
        });
    }
}

