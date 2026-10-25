/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  dorkbox.collections.IdentityMap
 */
package dorkbox.util.classes;

import dorkbox.collections.IdentityMap;
import java.lang.reflect.Array;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.concurrent.atomic.AtomicReferenceFieldUpdater;

public final class ClassHierarchy {
    private volatile IdentityMap<Class<?>, Class<?>> arrayCache;
    private volatile IdentityMap<Class<?>, Class<?>[]> superClassesCache;
    private static final AtomicReferenceFieldUpdater<ClassHierarchy, IdentityMap> arrayREF = AtomicReferenceFieldUpdater.newUpdater(ClassHierarchy.class, IdentityMap.class, "arrayCache");
    private static final AtomicReferenceFieldUpdater<ClassHierarchy, IdentityMap> superClassesREF = AtomicReferenceFieldUpdater.newUpdater(ClassHierarchy.class, IdentityMap.class, "superClassesCache");

    public ClassHierarchy(float loadFactor) {
        this.arrayCache = new IdentityMap(32, loadFactor);
        this.superClassesCache = new IdentityMap(32, loadFactor);
    }

    public Class<?>[] getClassAndSuperClasses(Class<?> clazz) {
        IdentityMap cache = (IdentityMap)ClassHierarchy.cast(superClassesREF.get(this));
        Class[] classes = (Class[])cache.get(clazz);
        if (classes == null) {
            Iterator<Class<?>> superTypesIterator = ClassHierarchy.getSuperTypes(clazz);
            ArrayList newList = new ArrayList(16);
            boolean isArray = clazz.isArray();
            newList.add(clazz);
            if (isArray) {
                while (superTypesIterator.hasNext()) {
                    Class<?> c = superTypesIterator.next();
                    if ((c = this.getArrayClass(c)) == clazz) continue;
                    newList.add(c);
                }
            } else {
                while (superTypesIterator.hasNext()) {
                    Class<?> c = superTypesIterator.next();
                    if (c == clazz) continue;
                    newList.add(c);
                }
            }
            classes = new Class[newList.size()];
            newList.toArray(classes);
            cache.put(clazz, (Object)classes);
            superClassesREF.lazySet(this, cache);
        }
        return classes;
    }

    public Class<?> getArrayClass(Class<?> c) {
        IdentityMap cache = (IdentityMap)ClassHierarchy.cast(arrayREF.get(this));
        Class<?> clazz = (Class<?>)cache.get(c);
        if (clazz == null) {
            Object[] newInstance = (Object[])Array.newInstance(c, 0);
            clazz = newInstance.getClass();
            cache.put(c, clazz);
            arrayREF.lazySet(this, cache);
        }
        return clazz;
    }

    public static Iterator<Class<?>> getSuperTypes(Class<?> from) {
        IdentityMap superclasses = new IdentityMap();
        ClassHierarchy.collectInterfaces(from, superclasses);
        while (!from.equals(Object.class) && !from.isInterface()) {
            superclasses.put(from.getSuperclass(), (Object)Boolean.TRUE);
            from = from.getSuperclass();
            ClassHierarchy.collectInterfaces(from, superclasses);
        }
        return superclasses.keys();
    }

    private static void collectInterfaces(Class<?> from, IdentityMap<Class<?>, Boolean> accumulator) {
        for (Class<?> intface : from.getInterfaces()) {
            accumulator.put(intface, (Object)Boolean.TRUE);
            ClassHierarchy.collectInterfaces(intface, accumulator);
        }
    }

    public void shutdown() {
        this.arrayCache.clear();
        this.superClassesCache.clear();
    }

    private static <T> T cast(Object obj) {
        return (T)obj;
    }
}

