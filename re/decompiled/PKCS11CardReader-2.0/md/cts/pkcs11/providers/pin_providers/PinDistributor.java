/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.pkcs11.providers.pin_providers;

import java.util.Collections;
import java.util.HashMap;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class PinDistributor {
    private static final Logger logger = LoggerFactory.getLogger(PinDistributor.class);
    private static final Map<String, char[]> sessionPins = Collections.synchronizedMap(new HashMap());

    private PinDistributor() {
    }

    public static void clearPinSession(String sessionId) {
        logger.info("clearPinSession={}", (Object)sessionId);
        sessionPins.remove(sessionId);
    }

    public static void setPinForSession(String sessionId, char[] pin) {
        logger.info("setPinForSession={}", (Object)sessionId);
        sessionPins.put(sessionId, pin);
    }

    public static char[] getPinForSesssion(String sessionId) {
        logger.info("getPinForSesssion={}", (Object)sessionId);
        return sessionPins.get(sessionId);
    }
}

