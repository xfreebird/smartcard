/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  md.cts.moldsign.transferobjects.models.WorkResult
 */
package md.cts.pkcs11.providers.workers;

import java.util.UUID;
import java.util.concurrent.Callable;
import md.cts.moldsign.transferobjects.models.WorkResult;
import md.cts.pkcs11.cards.exceptions.InvalidPinException;
import md.cts.pkcs11.cards.exceptions.OperationFailedException;

public abstract class AbstractWork<V extends WorkResult>
implements Callable<WorkResult> {
    private final String sessionId;

    protected AbstractWork() {
        UUID uid = UUID.randomUUID();
        this.sessionId = uid.toString();
    }

    public String getSessionId() {
        return this.sessionId;
    }

    @Override
    public abstract V call() throws OperationFailedException, InvalidPinException;
}

