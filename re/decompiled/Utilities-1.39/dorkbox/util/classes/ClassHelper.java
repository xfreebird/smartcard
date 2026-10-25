/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  net.jodah.typetools.TypeResolver
 *  net.jodah.typetools.TypeResolver$Unknown
 */
package dorkbox.util.classes;

import java.lang.reflect.Array;
import java.lang.reflect.GenericArrayType;
import java.lang.reflect.ParameterizedType;
import java.lang.reflect.Type;
import java.lang.reflect.TypeVariable;
import java.lang.reflect.WildcardType;
import java.util.Objects;
import net.jodah.typetools.TypeResolver;

public final class ClassHelper {
    public static Class<?> getGenericParameterAsClassForSuperClass(Class<?> genericTypeClass, Class<?> classToCheck, int genericParameterToGet) {
        Class<?> loopClassCheck = classToCheck;
        Class[] classes = TypeResolver.resolveRawArguments(genericTypeClass, loopClassCheck);
        if (classes.length > genericParameterToGet && classes[genericParameterToGet] != TypeResolver.Unknown.class) {
            return classes[genericParameterToGet];
        }
        while (loopClassCheck != Object.class) {
            Class aClass;
            Type superClassGeneric = loopClassCheck.getGenericSuperclass();
            classes = TypeResolver.resolveRawArguments((Type)superClassGeneric, loopClassCheck);
            if (classes.length > genericParameterToGet && (aClass = classes[genericParameterToGet]) != TypeResolver.Unknown.class) {
                return classes[genericParameterToGet];
            }
            loopClassCheck = loopClassCheck.getSuperclass();
        }
        for (loopClassCheck = classToCheck; loopClassCheck != Object.class; loopClassCheck = loopClassCheck.getSuperclass()) {
            Type[] genericInterfaces;
            for (Type genericInterface : genericInterfaces = loopClassCheck.getGenericInterfaces()) {
                Class aClass;
                classes = TypeResolver.resolveRawArguments((Type)genericInterface, loopClassCheck);
                if (classes.length <= genericParameterToGet || (aClass = classes[genericParameterToGet]) == TypeResolver.Unknown.class) continue;
                return aClass;
            }
        }
        return null;
    }

    public static Class<?> getRawType(Type type) {
        Objects.requireNonNull(type, "type == null");
        if (type instanceof Class) {
            return (Class)type;
        }
        if (type instanceof ParameterizedType) {
            ParameterizedType parameterizedType = (ParameterizedType)type;
            Type rawType = parameterizedType.getRawType();
            if (!(rawType instanceof Class)) {
                throw new IllegalArgumentException();
            }
            return (Class)rawType;
        }
        if (type instanceof GenericArrayType) {
            Type componentType = ((GenericArrayType)type).getGenericComponentType();
            return Array.newInstance(ClassHelper.getRawType(componentType), 0).getClass();
        }
        if (type instanceof TypeVariable) {
            return Object.class;
        }
        if (type instanceof WildcardType) {
            return ClassHelper.getRawType(((WildcardType)type).getUpperBounds()[0]);
        }
        throw new IllegalArgumentException("Expected a Class, ParameterizedType, or GenericArrayType, but <" + type + "> is of type " + type.getClass().getName());
    }

    public static boolean hasInterface(Class<?> requiredClass, Class<?> clazz) {
        Class<?>[] interfaces;
        if (requiredClass == clazz) {
            return true;
        }
        for (Class<?> iface : interfaces = clazz.getInterfaces()) {
            if (iface != requiredClass) continue;
            return true;
        }
        for (Class<?> iface : interfaces) {
            boolean b = ClassHelper.hasInterface(requiredClass, iface);
            if (!b) continue;
            return b;
        }
        for (Class<?> superClass = clazz.getSuperclass(); superClass != null && superClass != Object.class; superClass = superClass.getSuperclass()) {
            if (!ClassHelper.hasInterface(requiredClass, superClass)) continue;
            return true;
        }
        return false;
    }

    public static boolean hasParentClass(Class<?> parentClazz, Class<?> clazz) {
        Class<?> superClass = clazz.getSuperclass();
        if (parentClazz == superClass) {
            return true;
        }
        if (superClass != null && superClass != Object.class) {
            return ClassHelper.hasParentClass(parentClazz, superClass);
        }
        return false;
    }

    private ClassHelper() {
    }
}

