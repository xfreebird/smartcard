/*
 * Decompiled with CFR 0.152.
 */
package dorkbox.util.classes;

public abstract class ClassResolver {
    private static final int CALL_CONTEXT_OFFSET = 3;
    private static final CallerResolver CALLER_RESOLVER;

    public static Class<?> getCallerClass(int callerOffset) {
        return CALLER_RESOLVER.getClassContext()[3 + callerOffset];
    }

    static {
        try {
            CALLER_RESOLVER = new CallerResolver();
        }
        catch (SecurityException se) {
            throw new RuntimeException("ClassLoaderResolver: could not create CallerResolver: " + se);
        }
    }

    private static final class CallerResolver
    extends SecurityManager {
        private CallerResolver() {
        }

        @Override
        protected Class<?>[] getClassContext() {
            return super.getClassContext();
        }
    }
}

