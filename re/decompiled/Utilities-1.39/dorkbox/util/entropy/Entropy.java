/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.Metadata
 *  kotlin.Unit
 *  kotlin.jvm.internal.Intrinsics
 *  org.jetbrains.annotations.NotNull
 *  org.jetbrains.annotations.Nullable
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package dorkbox.util.entropy;

import dorkbox.util.entropy.EntropyProvider;
import dorkbox.util.entropy.SimpleEntropy;
import dorkbox.util.exceptions.InitializationException;
import kotlin.Metadata;
import kotlin.Unit;
import kotlin.jvm.internal.Intrinsics;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u00002\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u0012\n\u0000\n\u0002\u0010\u000e\n\u0000\n\u0002\u0010\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u0011\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002J\u0011\u0010\u0005\u001a\u00020\u00062\u0006\u0010\u0007\u001a\u00020\bH\u0086\u0002J/\u0010\t\u001a\u00020\n2\u000e\u0010\u000b\u001a\n\u0012\u0006\b\u0001\u0012\u00020\u00040\f2\u0012\u0010\r\u001a\n\u0012\u0006\b\u0001\u0012\u00020\u00010\u000e\"\u00020\u0001\u00a2\u0006\u0002\u0010\u000fR\u0010\u0010\u0003\u001a\u0004\u0018\u00010\u0004X\u0082\u000e\u00a2\u0006\u0002\n\u0000\u00a8\u0006\u0010"}, d2={"Ldorkbox/util/entropy/Entropy;", "", "()V", "provider", "Ldorkbox/util/entropy/EntropyProvider;", "get", "", "messageForUser", "", "init", "", "providerClass", "Ljava/lang/Class;", "args", "", "(Ljava/lang/Class;[Ljava/lang/Object;)V", "Utilities"})
public final class Entropy {
    @NotNull
    public static final Entropy INSTANCE = new Entropy();
    @Nullable
    private static EntropyProvider provider;

    private Entropy() {
    }

    @NotNull
    public final byte[] get(@NotNull String messageForUser) throws InitializationException {
        byte[] byArray;
        Intrinsics.checkNotNullParameter((Object)messageForUser, (String)"messageForUser");
        this.init(SimpleEntropy.class, new Object[0]);
        try {
            EntropyProvider entropyProvider = provider;
            Intrinsics.checkNotNull((Object)entropyProvider);
            byArray = entropyProvider.get(messageForUser);
        }
        catch (Exception e) {
            Logger logger = LoggerFactory.getLogger(Entropy.class);
            StringBuilder stringBuilder = new StringBuilder().append("Unable to get entropy bytes for ");
            EntropyProvider entropyProvider = provider;
            Intrinsics.checkNotNull((Object)entropyProvider);
            String error = stringBuilder.append(entropyProvider.getClass()).toString();
            logger.error(error, (Throwable)e);
            throw new InitializationException(error);
        }
        return byArray;
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    public final void init(@NotNull Class<? extends EntropyProvider> providerClass, Object ... args) throws InitializationException {
        Intrinsics.checkNotNullParameter(providerClass, (String)"providerClass");
        Intrinsics.checkNotNullParameter((Object)args, (String)"args");
        Class<Entropy> clazz = Entropy.class;
        synchronized (clazz) {
            boolean bl = false;
            if (provider == null) {
                try {
                    EntropyProvider entropyProvider;
                    if (args.length == 0) {
                        entropyProvider = providerClass.getDeclaredConstructor(new Class[0]).newInstance(new Object[0]);
                    } else {
                        Object[] objectArray = new Object[]{args};
                        entropyProvider = providerClass.getDeclaredConstructor(new Class[0]).newInstance(objectArray);
                    }
                    provider = entropyProvider;
                }
                catch (Exception e) {
                    Logger logger = LoggerFactory.getLogger(Entropy.class);
                    String error = "Unable to create entropy provider for " + providerClass + " with " + args.length + " args";
                    logger.error(error, (Throwable)e);
                    throw new InitializationException(error);
                }
            }
            Unit unit = Unit.INSTANCE;
        }
    }
}

