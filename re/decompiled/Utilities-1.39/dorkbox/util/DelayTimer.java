/*
 * Decompiled with CFR 0.152.
 */
package dorkbox.util;

import java.util.Timer;
import java.util.TimerTask;

public class DelayTimer {
    private final String name;
    private final boolean isDaemon;
    private final Runnable listener;
    private volatile Timer timer;
    private long delay;

    public DelayTimer(Runnable listener) {
        this(null, true, listener);
    }

    public DelayTimer(String name, boolean isDaemon, Runnable listener) {
        this.name = name;
        this.listener = listener;
        this.isDaemon = isDaemon;
    }

    public synchronized boolean isWaiting() {
        return this.timer != null;
    }

    public synchronized void cancel() {
        if (this.timer != null) {
            this.timer.cancel();
            this.timer.purge();
            this.timer = null;
        }
    }

    public synchronized void delay(long delay) {
        this.delay = delay;
        this.cancel();
        if (delay > 0L) {
            this.timer = this.name != null ? new Timer(this.name, this.isDaemon) : new Timer(this.isDaemon);
            TimerTask t = new TimerTask(){

                @Override
                public void run() {
                    Timer origTimer = DelayTimer.this.timer;
                    DelayTimer.this.listener.run();
                    if (origTimer != null) {
                        origTimer.cancel();
                        origTimer.purge();
                        if (origTimer == DelayTimer.this.timer) {
                            DelayTimer.this.timer = null;
                        }
                    }
                }
            };
            this.timer.schedule(t, delay);
        } else {
            this.listener.run();
            this.timer = null;
        }
    }

    public synchronized long getDelay() {
        return this.delay;
    }
}

