/*
 * Decompiled with CFR 0.152.
 */
package dorkbox.util;

import dorkbox.util.Tool;
import java.util.concurrent.ConcurrentHashMap;

public class ToolBox {
    private final ConcurrentHashMap<Class<?>, Tool> toolMap = new ConcurrentHashMap();

    public <Tool extends Tool> void register(Tool toolClass) {
        if (toolClass == null) {
            throw new IllegalArgumentException("Tool must not be null! Unable to add tool");
        }
        Tool put = this.toolMap.put(toolClass.getClass(), toolClass);
        if (put != null) {
            throw new IllegalArgumentException("Tool must be unique! Unable to add tool '" + toolClass + "'");
        }
    }

    public <Tool extends Tool> Tool get(Class<Tool> toolClass) {
        if (toolClass == null) {
            throw new IllegalArgumentException("Tool must not be null! Unable to add tool");
        }
        Tool tool = this.toolMap.get(toolClass);
        return (Tool)tool;
    }

    public <Tool extends Tool> void remove(Class<Tool> toolClass) {
        if (toolClass == null) {
            throw new IllegalArgumentException("Tool must not be null! Unable to remove tool");
        }
        this.toolMap.remove(toolClass);
    }
}

