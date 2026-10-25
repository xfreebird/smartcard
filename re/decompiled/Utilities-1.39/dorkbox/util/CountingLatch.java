/*
 * Decompiled with CFR 0.152.
 */
package dorkbox.util;

import java.util.concurrent.TimeUnit;
import java.util.concurrent.locks.AbstractQueuedSynchronizer;

public class CountingLatch {
    private final Sync sync;

    public CountingLatch() {
        this.sync = new Sync();
    }

    public CountingLatch(int initialCount) {
        this.sync = new Sync(initialCount);
    }

    public void increment() {
        this.sync.releaseShared(1);
    }

    public int getCount() {
        return this.sync.getCount();
    }

    public void decrement() {
        this.sync.releaseShared(-1);
    }

    public void await() throws InterruptedException {
        this.sync.acquireSharedInterruptibly(1);
    }

    public boolean await(long timeout) throws InterruptedException {
        return this.sync.tryAcquireSharedNanos(1, TimeUnit.MILLISECONDS.toNanos(timeout));
    }

    private static final class Sync
    extends AbstractQueuedSynchronizer {
        private static final long serialVersionUID = 1L;

        private Sync() {
        }

        private Sync(int initialState) {
            this.setState(initialState);
        }

        int getCount() {
            return this.getState();
        }

        @Override
        protected int tryAcquireShared(int acquires) {
            return this.getState() == 0 ? 1 : -1;
        }

        @Override
        protected boolean tryReleaseShared(int delta) {
            int nextc;
            int c;
            do {
                if ((nextc = (c = this.getState()) + delta) >= 0) continue;
                return false;
            } while (!this.compareAndSetState(c, nextc));
            return nextc == 0;
        }
    }
}

