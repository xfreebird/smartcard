/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  md.cts.moldsign.transferobjects.models.WorkResult
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.cryptography.schedulers;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Executor;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.FutureTask;
import md.cts.moldsign.transferobjects.models.WorkResult;
import md.cts.pkcs11.cards.exceptions.InvalidPinException;
import md.cts.pkcs11.cards.exceptions.OperationFailedException;
import md.cts.pkcs11.providers.workers.AbstractWork;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class Scheduler {
    private static final Logger logger = LoggerFactory.getLogger(Scheduler.class);
    private final Map<String, Future<WorkResult>> taskSessions = new HashMap<String, Future<WorkResult>>();
    private final Executor executor = Executors.newSingleThreadExecutor();

    public String scheduleWorker(AbstractWork<? extends WorkResult> worker) {
        String name = worker.toString();
        if (!name.startsWith("md.cts.pkcs11.providers.workers.CheckCardPresentWorker@") && !name.startsWith("md.cts.pkcs11.providers.workers.GetSlotsWorker@")) {
            logger.info("{}", (Object)name);
        }
        String sessionId = worker.getSessionId();
        FutureTask<WorkResult> task = new FutureTask<WorkResult>(worker);
        this.executor.execute(task);
        this.taskSessions.put(sessionId, task);
        return sessionId;
    }

    public Future<WorkResult> getResult(String sessionId) {
        Future<WorkResult> task = this.taskSessions.get(sessionId);
        this.taskSessions.remove(sessionId);
        return task;
    }

    public <T extends WorkResult> T getResult(String sessionId, Class<T> type) throws OperationFailedException, InvalidPinException, ClassCastException {
        Future<WorkResult> task = this.taskSessions.get(sessionId);
        this.taskSessions.remove(sessionId);
        try {
            return (T)((WorkResult)type.cast(task.get()));
        }
        catch (InterruptedException ex) {
            logger.error("Scheduler getResult InterruptedException", (Throwable)ex);
            throw new OperationFailedException(ex);
        }
        catch (ExecutionException ex) {
            logger.error("Scheduler getResult ExecutionException", (Throwable)ex);
            if (ex.getCause() instanceof OperationFailedException) {
                throw (OperationFailedException)ex.getCause();
            }
            if (ex.getCause() instanceof InvalidPinException) {
                throw (InvalidPinException)ex.getCause();
            }
            throw new OperationFailedException(ex);
        }
    }
}

