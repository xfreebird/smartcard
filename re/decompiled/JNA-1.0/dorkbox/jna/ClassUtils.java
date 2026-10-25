/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.sun.jna.JNIEnv
 *  com.sun.jna.Library
 *  com.sun.jna.Native
 *  com.sun.jna.NativeLibrary
 *  com.sun.jna.win32.StdCallFunctionMapper
 *  dorkbox.os.OS
 */
package dorkbox.jna;

import com.sun.jna.JNIEnv;
import com.sun.jna.Library;
import com.sun.jna.Native;
import com.sun.jna.NativeLibrary;
import com.sun.jna.win32.StdCallFunctionMapper;
import dorkbox.jna.ClassLoaderAccessory;
import dorkbox.os.OS;
import java.lang.reflect.Method;
import java.util.HashMap;
import java.util.concurrent.atomic.AtomicBoolean;

public class ClassUtils {
    private static final JVM libJvm;
    private static final String libName;
    private static AtomicBoolean loaded;

    public static void defineClass(byte[] classBytes) throws Exception {
        ClassLoader classLoader = Thread.currentThread().getContextClassLoader();
        ClassUtils.defineClass(classLoader, classBytes);
    }

    public static void defineClass(ClassLoader classLoader, byte[] classBytes) throws Exception {
        libJvm.JVM_DefineClass(JNIEnv.CURRENT, null, classLoader, classBytes, classBytes.length, null);
    }

    public static Class<?> findLoadedClass(ClassLoader classLoader, String className) {
        if (!loaded.getAndSet(true)) {
            byte[] classLoaderAccessorBytes = new byte[]{-54, -2, -70, -66, 0, 0, 0, 52, 0, 19, 1, 0, 29, 106, 97, 118, 97, 47, 108, 97, 110, 103, 47, 67, 108, 97, 115, 115, 76, 111, 97, 100, 101, 114, 65, 99, 99, 101, 115, 115, 111, 114, 7, 0, 1, 1, 0, 16, 106, 97, 118, 97, 47, 108, 97, 110, 103, 47, 79, 98, 106, 101, 99, 116, 7, 0, 3, 1, 0, 10, 83, 111, 117, 114, 99, 101, 70, 105, 108, 101, 1, 0, 24, 67, 108, 97, 115, 115, 76, 111, 97, 100, 101, 114, 65, 99, 99, 101, 115, 115, 111, 114, 46, 106, 97, 118, 97, 1, 0, 15, 102, 105, 110, 100, 76, 111, 97, 100, 101, 100, 67, 108, 97, 115, 115, 1, 0, 60, 40, 76, 106, 97, 118, 97, 47, 108, 97, 110, 103, 47, 67, 108, 97, 115, 115, 76, 111, 97, 100, 101, 114, 59, 76, 106, 97, 118, 97, 47, 108, 97, 110, 103, 47, 83, 116, 114, 105, 110, 103, 59, 41, 76, 106, 97, 118, 97, 47, 108, 97, 110, 103, 47, 67, 108, 97, 115, 115, 59, 1, 0, 21, 106, 97, 118, 97, 47, 108, 97, 110, 103, 47, 67, 108, 97, 115, 115, 76, 111, 97, 100, 101, 114, 7, 0, 9, 1, 0, 37, 40, 76, 106, 97, 118, 97, 47, 108, 97, 110, 103, 47, 83, 116, 114, 105, 110, 103, 59, 41, 76, 106, 97, 118, 97, 47, 108, 97, 110, 103, 47, 67, 108, 97, 115, 115, 59, 12, 0, 7, 0, 11, 10, 0, 10, 0, 12, 1, 0, 4, 67, 111, 100, 101, 1, 0, 6, 60, 105, 110, 105, 116, 62, 1, 0, 3, 40, 41, 86, 12, 0, 15, 0, 16, 10, 0, 4, 0, 17, 0, 33, 0, 2, 0, 4, 0, 0, 0, 0, 0, 2, 0, 9, 0, 7, 0, 8, 0, 1, 0, 14, 0, 0, 0, 18, 0, 2, 0, 2, 0, 0, 0, 6, 42, 43, -74, 0, 13, -80, 0, 0, 0, 0, 0, 1, 0, 15, 0, 16, 0, 1, 0, 14, 0, 0, 0, 17, 0, 1, 0, 1, 0, 0, 0, 5, 42, -73, 0, 18, -79, 0, 0, 0, 0, 0, 1, 0, 5, 0, 0, 0, 2, 0, 6};
            try {
                ClassUtils.defineClass(null, classLoaderAccessorBytes);
            }
            catch (Exception e) {
                throw new RuntimeException(e);
            }
            byte[] classFixerBytes = new byte[]{-54, -2, -70, -66, 0, 0, 0, 52, 0, 22, 1, 0, 32, 100, 111, 114, 107, 98, 111, 120, 47, 106, 110, 97, 47, 67, 108, 97, 115, 115, 76, 111, 97, 100, 101, 114, 65, 99, 99, 101, 115, 115, 111, 114, 121, 7, 0, 1, 1, 0, 16, 106, 97, 118, 97, 47, 108, 97, 110, 103, 47, 79, 98, 106, 101, 99, 116, 7, 0, 3, 1, 0, 6, 60, 105, 110, 105, 116, 62, 1, 0, 3, 40, 41, 86, 1, 0, 4, 67, 111, 100, 101, 1, 0, 15, 76, 105, 110, 101, 78, 117, 109, 98, 101, 114, 84, 97, 98, 108, 101, 1, 0, 18, 76, 111, 99, 97, 108, 86, 97, 114, 105, 97, 98, 108, 101, 84, 97, 98, 108, 101, 1, 0, 4, 116, 104, 105, 115, 1, 0, 34, 76, 100, 111, 114, 107, 98, 111, 120, 47, 106, 110, 97, 47, 67, 108, 97, 115, 115, 76, 111, 97, 100, 101, 114, 65, 99, 99, 101, 115, 115, 111, 114, 121, 59, 12, 0, 5, 0, 6, 10, 0, 4, 0, 12, 1, 0, 15, 102, 105, 110, 100, 76, 111, 97, 100, 101, 100, 67, 108, 97, 115, 115, 1, 0, 60, 40, 76, 106, 97, 118, 97, 47, 108, 97, 110, 103, 47, 67, 108, 97, 115, 115, 76, 111, 97, 100, 101, 114, 59, 76, 106, 97, 118, 97, 47, 108, 97, 110, 103, 47, 83, 116, 114, 105, 110, 103, 59, 41, 76, 106, 97, 118, 97, 47, 108, 97, 110, 103, 47, 67, 108, 97, 115, 115, 59, 1, 0, 29, 106, 97, 118, 97, 47, 108, 97, 110, 103, 47, 67, 108, 97, 115, 115, 76, 111, 97, 100, 101, 114, 65, 99, 99, 101, 115, 115, 111, 114, 7, 0, 16, 12, 0, 14, 0, 15, 10, 0, 17, 0, 18, 1, 0, 10, 83, 111, 117, 114, 99, 101, 70, 105, 108, 101, 1, 0, 25, 67, 108, 97, 115, 115, 76, 111, 97, 100, 101, 114, 65, 99, 99, 101, 115, 115, 111, 114, 121, 46, 106, 97, 118, 97, 0, 32, 0, 2, 0, 4, 0, 0, 0, 0, 0, 2, 0, 0, 0, 5, 0, 6, 0, 1, 0, 7, 0, 0, 0, 47, 0, 1, 0, 1, 0, 0, 0, 5, 42, -73, 0, 13, -79, 0, 0, 0, 2, 0, 8, 0, 0, 0, 6, 0, 1, 0, 0, 0, 3, 0, 9, 0, 0, 0, 12, 0, 1, 0, 0, 0, 5, 0, 10, 0, 11, 0, 0, 0, 12, 0, 14, 0, 15, 0, 1, 0, 7, 0, 0, 0, 18, 0, 2, 0, 2, 0, 0, 0, 6, 42, 43, -72, 0, 19, -80, 0, 0, 0, 0, 0, 1, 0, 20, 0, 0, 0, 2, 0, 21};
            try {
                ClassUtils.defineClass(classLoader, classFixerBytes);
            }
            catch (Exception e) {
                throw new RuntimeException(e);
            }
        }
        return ClassLoaderAccessory.findLoadedClass(classLoader, className);
    }

    public static boolean isClassLoaded(ClassLoader classLoader, String className) {
        return null != ClassUtils.findLoadedClass(classLoader, className);
    }

    static {
        if (OS.INSTANCE.isMacOsX()) {
            if (OS.INSTANCE.getJavaVersion() < 7) {
                libName = "JavaVM";
            } else {
                String javaLocation = System.getProperty("java.home");
                libName = javaLocation + "/lib/server/libjvm.dylib";
            }
        } else {
            libName = "jvm";
        }
        HashMap<String, Object> options = new HashMap<String, Object>();
        options.put("allow-objects", Boolean.TRUE);
        if (OS.INSTANCE.isWindows() && OS.INSTANCE.is32bit()) {
            options.put("function-mapper", new StdCallFunctionMapper(){

                public String getFunctionName(NativeLibrary library, Method method) {
                    String methodName = method.getName();
                    if (methodName.equals("JVM_DefineClass")) {
                        return "_JVM_DefineClass@24";
                    }
                    return methodName;
                }
            });
            libJvm = (JVM)Native.load((String)libName, JVM.class, options);
        } else {
            libJvm = (JVM)Native.load((String)libName, JVM.class, options);
        }
        loaded = new AtomicBoolean(false);
    }

    public static interface JVM
    extends Library {
        public void JVM_DefineClass(JNIEnv var1, String var2, Object var3, byte[] var4, int var5, Object var6);
    }
}

