/*
 * Decompiled with CFR 0.152.
 */
package dorkbox.util.userManagement;

import dorkbox.util.userManagement.UserManagement;
import java.io.Serializable;
import java.util.Collection;
import java.util.Collections;
import java.util.HashSet;
import java.util.Set;
import java.util.UUID;

public final class Group
implements Serializable {
    private final UUID uuid;
    private String name;
    private Set<UUID> users = new HashSet<UUID>();

    public Group(String name) {
        this(name, UserManagement.UUID_GENERATOR.generate());
    }

    Group(String name, UUID uuid) {
        this.name = name;
        this.uuid = uuid;
    }

    public UUID getUuid() {
        return this.uuid;
    }

    public String getName() {
        return this.name;
    }

    public synchronized void addUser(UUID user) {
        this.users.add(user);
    }

    public synchronized void removeUser(UUID user) {
        this.users.remove(user);
    }

    public synchronized Collection<UUID> getUsers() {
        return Collections.unmodifiableCollection(this.users);
    }

    public synchronized boolean isEmpty() {
        return this.users.isEmpty();
    }

    public synchronized void remove() {
        this.users.clear();
    }

    public String toString() {
        return "Group '" + this.name + '\'';
    }

    public boolean equals(Object o) {
        if (this == o) {
            return true;
        }
        if (o == null || this.getClass() != o.getClass()) {
            return false;
        }
        Group group = (Group)o;
        return this.uuid != null ? this.uuid.equals(group.uuid) : group.uuid == null;
    }

    public int hashCode() {
        return this.uuid != null ? this.uuid.hashCode() : 0;
    }
}

