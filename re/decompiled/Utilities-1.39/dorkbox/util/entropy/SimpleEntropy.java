/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.Metadata
 *  kotlin.Unit
 *  kotlin.jvm.internal.Intrinsics
 *  org.jetbrains.annotations.NotNull
 */
package dorkbox.util.entropy;

import dorkbox.util.entropy.EntropyProvider;
import java.security.SecureRandom;
import kotlin.Metadata;
import kotlin.Unit;
import kotlin.jvm.internal.Intrinsics;
import org.jetbrains.annotations.NotNull;

@Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u0000\u001e\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u0012\n\u0000\n\u0002\u0010\u000e\n\u0000\u0018\u00002\u00020\u0001B\u0005\u00a2\u0006\u0002\u0010\u0002J\u0011\u0010\u0005\u001a\u00020\u00062\u0006\u0010\u0007\u001a\u00020\bH\u0096\u0002R\u000e\u0010\u0003\u001a\u00020\u0004X\u0082\u0004\u00a2\u0006\u0002\n\u0000\u00a8\u0006\t"}, d2={"Ldorkbox/util/entropy/SimpleEntropy;", "Ldorkbox/util/entropy/EntropyProvider;", "()V", "secureRandom", "Ljava/security/SecureRandom;", "get", "", "messageForUser", "", "Utilities"})
public final class SimpleEntropy
implements EntropyProvider {
    @NotNull
    private final SecureRandom secureRandom = new SecureRandom();

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    @Override
    @NotNull
    public byte[] get(@NotNull String messageForUser) {
        Intrinsics.checkNotNullParameter((Object)messageForUser, (String)"messageForUser");
        byte[] rand = new byte[256];
        SecureRandom secureRandom = this.secureRandom;
        synchronized (secureRandom) {
            boolean bl = false;
            this.secureRandom.nextBytes(rand);
            Unit unit = Unit.INSTANCE;
        }
        return rand;
    }
}

