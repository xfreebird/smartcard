/*
 * Decompiled with CFR 0.152.
 */
package dorkbox.util.userManagement;

import dorkbox.util.userManagement.UserManagement;
import java.io.Serializable;
import java.util.Collections;
import java.util.HashSet;
import java.util.Set;
import java.util.UUID;

public class User
implements Serializable {
    private final UUID uuid;
    private final byte[] salt = new byte[256];
    protected String name;
    private final Set<UUID> groups = new HashSet<UUID>();

    public User() {
        this.uuid = UserManagement.UUID_GENERATOR.generate();
        UserManagement.RANDOM.nextBytes(this.salt);
    }

    User(UUID uuid, byte[] salt) {
        this.uuid = uuid;
        for (byte this.salt[i] : salt) {
        }
    }

    public final UUID getUUID() {
        return this.uuid;
    }

    public final byte[] getSalt() {
        return this.salt;
    }

    public final Set<UUID> getGroups() {
        return Collections.unmodifiableSet(this.groups);
    }

    public final String getName() {
        return this.name;
    }

    public final void setName(String name) {
        this.name = name;
    }

    public final boolean equals(Object o) {
        if (this == o) {
            return true;
        }
        if (o == null || this.getClass() != o.getClass()) {
            return false;
        }
        User user = (User)o;
        return this.uuid.equals(user.uuid);
    }

    public final int hashCode() {
        return this.uuid.hashCode();
    }

    public final String toString() {
        return "User {" + this.uuid + ", '" + this.name + '\'' + '}';
    }
}

