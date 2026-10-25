/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.fasterxml.uuid.Generators
 *  com.fasterxml.uuid.impl.RandomBasedGenerator
 *  com.fasterxml.uuid.impl.UUIDUtil
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package dorkbox.util.userManagement;

import com.fasterxml.uuid.Generators;
import com.fasterxml.uuid.impl.RandomBasedGenerator;
import com.fasterxml.uuid.impl.UUIDUtil;
import dorkbox.util.userManagement.Group;
import dorkbox.util.userManagement.User;
import java.security.SecureRandom;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class UserManagement {
    private static final Logger logger = LoggerFactory.getLogger((String)UserManagement.class.getSimpleName());
    static final RandomBasedGenerator UUID_GENERATOR = Generators.randomBasedGenerator();
    static final SecureRandom RANDOM = new SecureRandom();
    public final Group ADMIN;
    private Map<UUID, User> users = new HashMap<UUID, User>();
    private Map<UUID, Group> groups = new HashMap<UUID, Group>();

    public UserManagement() {
        byte[] buffer = new byte[16];
        int bufferLength = buffer.length;
        for (int i = 0; i < bufferLength; ++i) {
            buffer[i] = 0;
        }
        UUID uuid = UUIDUtil.uuid((byte[])buffer);
        this.ADMIN = new Group("System", uuid);
        this.groups.put(uuid, this.ADMIN);
    }

    public User authenticate(String user) {
        return null;
    }

    public User createUser() {
        User user = new User();
        this.addUser(user);
        return user;
    }

    private void addUser(User user) {
    }

    private void removeUser(User user) {
        this.users.remove(user);
    }

    public Map<UUID, User> getUsers() {
        return Collections.unmodifiableMap(this.users);
    }

    public User getUser(UUID uuid) {
        return this.users.get(uuid);
    }

    public Group createGroup(String groupName) {
        Group group = new Group(groupName);
        this.addGroup(group);
        return group;
    }

    public void addGroup(Group group) {
    }

    public void removeGroup(Group group) {
        if (group != this.ADMIN) {
            this.groups.remove(group);
        }
    }
}

