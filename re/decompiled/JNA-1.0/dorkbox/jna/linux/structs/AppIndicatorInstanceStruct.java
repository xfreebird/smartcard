/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.sun.jna.Pointer
 *  com.sun.jna.Structure
 */
package dorkbox.jna.linux.structs;

import com.sun.jna.Pointer;
import com.sun.jna.Structure;
import dorkbox.jna.linux.AppIndicator;
import dorkbox.jna.linux.structs.GObjectStruct;
import java.util.Arrays;
import java.util.List;

public class AppIndicatorInstanceStruct
extends Structure {
    public GObjectStruct parent;
    public Pointer priv;

    protected List<String> getFieldOrder() {
        return Arrays.asList("parent", "priv");
    }

    public void app_indicator_set_title(String title) {
        AppIndicator.app_indicator_set_title(this.getPointer(), title);
    }

    public void app_indicator_set_status(int status) {
        AppIndicator.app_indicator_set_status(this.getPointer(), status);
    }

    public void app_indicator_set_menu(Pointer menu) {
        AppIndicator.app_indicator_set_menu(this.getPointer(), menu);
    }

    public void app_indicator_set_icon(String icon_name) {
        AppIndicator.app_indicator_set_icon(this.getPointer(), icon_name);
    }
}

