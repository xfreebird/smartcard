/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  dorkbox.os.OS
 *  org.slf4j.Logger
 */
package dorkbox.util;

import dorkbox.os.OS;
import dorkbox.util.NamedThreadFactory;
import java.util.ArrayList;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.atomic.AtomicInteger;
import org.slf4j.Logger;

public abstract class ParallelProcessor<Task> {
    private static final Object SENTINEL = new Object[0];
    private final int numberOfThreads;
    private final ArrayList<Thread> threads;
    private final ArrayBlockingQueue<Object> queue;
    private final CountDownLatch latch;
    private final int totalWorkload;
    private final AtomicInteger currentProgress = new AtomicInteger(0);

    public ParallelProcessor() {
        this(-1, OS.INSTANCE.getOptimumNumberOfThreads(), null);
    }

    public ParallelProcessor(int totalWorkload) {
        this(totalWorkload, OS.INSTANCE.getOptimumNumberOfThreads(), null);
    }

    public ParallelProcessor(int totalWorkload, int numberOfThreads) {
        this(totalWorkload, numberOfThreads, null);
    }

    public ParallelProcessor(int totalWorkload, int numberOfThreads, final Logger logger) {
        this.totalWorkload = totalWorkload;
        this.numberOfThreads = numberOfThreads;
        this.latch = new CountDownLatch(this.numberOfThreads);
        this.queue = new ArrayBlockingQueue(numberOfThreads);
        this.threads = new ArrayList(numberOfThreads);
        ThreadGroup threadGroup = new ThreadGroup(Thread.currentThread().getThreadGroup(), "ParallelProcessor");
        NamedThreadFactory dispatchThreadFactory = new NamedThreadFactory("Processor", threadGroup);
        for (int i = 0; i < numberOfThreads; ++i) {
            Runnable runnable = new Runnable(){

                /*
                 * WARNING - Removed try catching itself - possible behaviour change.
                 */
                @Override
                public void run() {
                    ParallelProcessor processor = ParallelProcessor.this;
                    ArrayBlockingQueue queue = processor.queue;
                    Worker worker = ParallelProcessor.this.createWorker();
                    while (true) {
                        Object taken;
                        try {
                            taken = queue.take();
                            if (taken == SENTINEL) {
                                ParallelProcessor.this.latch.countDown();
                                return;
                            }
                        }
                        catch (Throwable ignored) {
                            return;
                        }
                        Object task = taken;
                        try {
                            worker.process(task);
                            ParallelProcessor.this.workComplete(ParallelProcessor.this, task);
                            continue;
                        }
                        catch (Throwable t) {
                            if (logger != null) {
                                logger.error("Error during execution of work!", t);
                                continue;
                            }
                            t.printStackTrace();
                            continue;
                        }
                        finally {
                            ParallelProcessor.this.currentProgress.getAndIncrement();
                            AtomicInteger atomicInteger = ParallelProcessor.this.currentProgress;
                            synchronized (atomicInteger) {
                                ParallelProcessor.this.currentProgress.notifyAll();
                            }
                            continue;
                        }
                        break;
                    }
                }
            };
            Thread runner = dispatchThreadFactory.newThread(runnable);
            this.threads.add(runner);
        }
        for (Thread thread : this.threads) {
            thread.start();
        }
    }

    public abstract Worker createWorker();

    public abstract void workComplete(ParallelProcessor var1, Task var2);

    public boolean hasAvailableWorker() {
        return this.queue.size() < this.numberOfThreads;
    }

    public void process(Task taskToProcess) throws InterruptedException {
        this.queue.put(taskToProcess);
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    public void waitUntilDone() throws InterruptedException {
        if (this.totalWorkload > 0) {
            while (this.currentProgress.get() - this.totalWorkload != 0) {
                AtomicInteger atomicInteger = this.currentProgress;
                synchronized (atomicInteger) {
                    this.currentProgress.wait(10000L);
                }
            }
        }
        for (int i = 0; i < this.threads.size(); ++i) {
            this.queue.put(SENTINEL);
        }
        this.latch.await();
    }

    public float getProgress() {
        int i = this.currentProgress.get();
        if (this.totalWorkload == -1) {
            return i;
        }
        if (i == 0) {
            return 0.0f;
        }
        if (i == this.totalWorkload) {
            return 1.0f;
        }
        return (float)i / (float)this.totalWorkload;
    }

    public static interface Worker<Task> {
        public boolean process(Task var1);
    }
}

