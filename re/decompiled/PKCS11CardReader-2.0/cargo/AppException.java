/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package cargo;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class AppException
extends Exception {
    private static final Logger logger = LoggerFactory.getLogger(AppException.class);

    public AppException(String message) {
        super(message);
        logger.error(message);
    }

    public AppException(Throwable cause) {
        super(cause);
        logger.error("", cause);
    }

    public AppException(String message, Throwable cause) {
        super(message, cause);
        logger.error(message, cause);
    }
}

