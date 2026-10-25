/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  dorkbox.collections.IdentityMap
 */
package dorkbox.util.classes;

import dorkbox.collections.IdentityMap;
import java.lang.annotation.Annotation;
import java.lang.reflect.AnnotatedElement;
import java.lang.reflect.Method;
import java.util.ArrayList;

public final class ReflectionUtils {
    private static final Method[] EMPTY_METHODS = new Method[0];

    private ReflectionUtils() {
    }

    public static <A extends Annotation> Method[] getMethods(Class<?> target, Class<A> annotationClass) {
        ArrayList<Method> methods = new ArrayList<Method>();
        ReflectionUtils.getMethods(target, annotationClass, methods);
        return methods.toArray(EMPTY_METHODS);
    }

    private static <A extends Annotation> void getMethods(Class<?> target, Class<A> annotationClass, ArrayList<Method> methods) {
        try {
            for (Method method : target.getDeclaredMethods()) {
                if (ReflectionUtils.getAnnotation(method, annotationClass) == null) continue;
                methods.add(method);
            }
        }
        catch (Exception exception) {
            // empty catch block
        }
        if (!target.equals(Object.class)) {
            ReflectionUtils.getMethods(target.getSuperclass(), annotationClass, methods);
        }
    }

    public static Method getOverridingMethod(Method overridingMethod, Class<?> subclass) {
        Class<?> current = subclass;
        while (!current.equals(overridingMethod.getDeclaringClass())) {
            try {
                return current.getDeclaredMethod(overridingMethod.getName(), overridingMethod.getParameterTypes());
            }
            catch (NoSuchMethodException e) {
                current = current.getSuperclass();
            }
        }
        return null;
    }

    public static boolean containsOverridingMethod(Method[] allMethods, Method methodToCheck) {
        for (Method method : allMethods) {
            if (!ReflectionUtils.isOverriddenBy(methodToCheck, method)) continue;
            return true;
        }
        return false;
    }

    private static <A extends Annotation> A getAnnotation(AnnotatedElement from, Class<A> annotationType, IdentityMap<AnnotatedElement, Boolean> visited) {
        if (visited.containsKey((Object)from)) {
            return null;
        }
        visited.put((Object)from, (Object)Boolean.TRUE);
        A ann = from.getAnnotation(annotationType);
        if (ann != null) {
            return ann;
        }
        for (Annotation metaAnn : from.getAnnotations()) {
            ann = ReflectionUtils.getAnnotation(metaAnn.annotationType(), annotationType, visited);
            if (ann == null) continue;
            return ann;
        }
        return null;
    }

    public static <A extends Annotation> A getAnnotation(AnnotatedElement from, Class<A> annotationType) {
        return ReflectionUtils.getAnnotation(from, annotationType, (IdentityMap<AnnotatedElement, Boolean>)new IdentityMap());
    }

    private static boolean isOverriddenBy(Method superclassMethod, Method subclassMethod) {
        if (superclassMethod.getDeclaringClass().equals(subclassMethod.getDeclaringClass()) || !superclassMethod.getDeclaringClass().isAssignableFrom(subclassMethod.getDeclaringClass()) || !superclassMethod.getName().equals(subclassMethod.getName())) {
            return false;
        }
        Class<?>[] superClassMethodParameters = superclassMethod.getParameterTypes();
        Class<?>[] subClassMethodParameters = subclassMethod.getParameterTypes();
        for (int i = 0; i < subClassMethodParameters.length; ++i) {
            if (superClassMethodParameters[i].equals(subClassMethodParameters[i])) continue;
            return false;
        }
        return true;
    }
}

