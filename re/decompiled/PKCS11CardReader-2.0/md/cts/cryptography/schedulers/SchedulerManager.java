/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.cryptography.schedulers;

import java.util.Collections;
import java.util.HashMap;
import java.util.Map;
import md.cts.cryptography.schedulers.Scheduler;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class SchedulerManager {
    private static final String DEFAULT_SCHEDULER_NAME = "DEFAULT SCHEDULER";
    private static final Logger logger = LoggerFactory.getLogger(SchedulerManager.class);
    private static SchedulerManager instance = null;
    private final Map<String, Scheduler> schedulers = Collections.synchronizedMap(new HashMap());

    private SchedulerManager() {
    }

    public static synchronized Scheduler get(String schedulerName) {
        if (instance == null) {
            instance = new SchedulerManager();
        }
        return instance.ensureScheduler(schedulerName);
    }

    public static Scheduler getDefault() {
        return SchedulerManager.get(DEFAULT_SCHEDULER_NAME);
    }

    private Scheduler ensureScheduler(String schedulerName) {
        if (!this.schedulers.containsKey(schedulerName)) {
            logger.info("Creating new scheduler for id {}", (Object)schedulerName);
            this.schedulers.put(schedulerName, new Scheduler());
        }
        return this.schedulers.get(schedulerName);
    }
}

