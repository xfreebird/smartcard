/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.sun.jna.Function
 *  com.sun.jna.Pointer
 */
package dorkbox.jna.linux;

import com.sun.jna.Function;
import com.sun.jna.Pointer;
import dorkbox.jna.linux.FuncCallback;
import dorkbox.jna.linux.GMainContext;
import dorkbox.jna.linux.GMainLoop;
import dorkbox.jna.linux.Gtk;
import dorkbox.jna.linux.structs.GtkStyle;

public class Gtk2
implements Gtk {
    @Override
    public native boolean gtk_init_check(int var1);

    @Override
    public native GMainLoop g_main_loop_new(Pointer var1, boolean var2);

    @Override
    public native GMainContext g_main_loop_get_context(GMainLoop var1);

    @Override
    public native void g_main_loop_run(GMainLoop var1);

    @Override
    public native void g_main_context_invoke(GMainContext var1, FuncCallback var2, Pointer var3);

    @Override
    public native void g_main_loop_quit(GMainLoop var1);

    @Override
    public native Pointer gtk_menu_new();

    @Override
    public native void gtk_menu_item_set_submenu(Pointer var1, Pointer var2);

    @Override
    public native Pointer gtk_separator_menu_item_new();

    @Override
    public native Pointer gtk_image_new_from_file(String var1);

    @Override
    public native void gtk_check_menu_item_set_active(Pointer var1, boolean var2);

    @Override
    public native Pointer gtk_image_menu_item_new_with_mnemonic(String var1);

    @Override
    public native Pointer gtk_check_menu_item_new_with_mnemonic(String var1);

    @Override
    public native void gtk_image_menu_item_set_image(Pointer var1, Pointer var2);

    @Override
    public native void gtk_image_menu_item_set_always_show_image(Pointer var1, boolean var2);

    @Override
    public native Pointer gtk_status_icon_new();

    @Override
    public native Pointer gdk_get_default_root_window();

    @Override
    public native Pointer gdk_screen_get_default();

    @Override
    public native double gdk_screen_get_resolution(Pointer var1);

    @Override
    public native void gtk_status_icon_set_from_file(Pointer var1, String var2);

    @Override
    public native void gtk_status_icon_set_visible(Pointer var1, boolean var2);

    @Override
    public native void gtk_status_icon_set_tooltip_text(Pointer var1, String var2);

    @Override
    public native void gtk_status_icon_set_title(Pointer var1, String var2);

    @Override
    public native void gtk_status_icon_set_name(Pointer var1, String var2);

    @Override
    public native void gtk_menu_popup(Pointer var1, Pointer var2, Pointer var3, Function var4, Pointer var5, int var6, int var7);

    @Override
    public native void gtk_menu_item_set_label(Pointer var1, String var2);

    @Override
    public native void gtk_menu_shell_append(Pointer var1, Pointer var2);

    @Override
    public native void gtk_widget_set_sensitive(Pointer var1, boolean var2);

    @Override
    public native void gtk_widget_show_all(Pointer var1);

    @Override
    public native void gtk_container_remove(Pointer var1, Pointer var2);

    @Override
    public native void gtk_widget_destroy(Pointer var1);

    @Override
    public native Pointer gtk_settings_get_for_screen(Pointer var1);

    @Override
    public native Pointer gtk_settings_get_default();

    @Override
    public native GtkStyle gtk_rc_get_style(Pointer var1);

    @Override
    public native void gtk_container_add(Pointer var1, Pointer var2);

    @Override
    public native Pointer gtk_bin_get_child(Pointer var1);

    @Override
    public native Pointer gtk_label_get_layout(Pointer var1);

    @Override
    public native void pango_layout_get_pixel_extents(Pointer var1, Pointer var2, Pointer var3);

    @Override
    public native void gtk_widget_realize(Pointer var1);

    @Override
    public native Pointer gtk_offscreen_window_new();

    @Override
    public native void gtk_widget_size_request(Pointer var1, Pointer var2);

    @Override
    public native Pointer gtk_image_menu_item_new_from_stock(String var1, Pointer var2);

    @Override
    @Deprecated
    public native boolean gtk_show_uri(Pointer var1, String var2, int var3, Pointer var4);

    @Override
    public native void gtk_widget_set_tooltip_text(Pointer var1, String var2);

    @Override
    public native Pointer gdk_display_get_default();
}

