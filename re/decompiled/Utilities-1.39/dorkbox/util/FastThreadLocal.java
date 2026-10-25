/*
 * Decompiled with CFR 0.152.
 */
package dorkbox.util;

import java.util.Arrays;

public class FastThreadLocal<T> {
    private T[] threadIDMap = new Object[1];

    public T initialValue() {
        return null;
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    public void set(T value) {
        int id = (int)Thread.currentThread().getId();
        FastThreadLocal fastThreadLocal = this;
        synchronized (fastThreadLocal) {
            int len = this.threadIDMap.length;
            if (len <= id) {
                this.threadIDMap = Arrays.copyOf(this.threadIDMap, id + 1);
            }
            this.threadIDMap[id] = value;
        }
    }

    public final T get() {
        T value;
        T[] threadIDMap = this.threadIDMap;
        int id = (int)Thread.currentThread().getId();
        T t = value = threadIDMap.length <= id ? null : (T)threadIDMap[id];
        if (value == null) {
            value = this.initialValue();
            this.set(value);
        }
        return value;
    }

    public void remove() {
        this.set(null);
    }
}

