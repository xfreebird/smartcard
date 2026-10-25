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
import dorkbox.jna.linux.Gtk2;
import dorkbox.jna.linux.Gtk3;
import dorkbox.jna.linux.GtkLoader;
import dorkbox.jna.linux.structs.GtkStyle;

public interface Gtk {
    public static final int FALSE = 0;
    public static final int TRUE = 1;
    public static final int MAJOR = GtkLoader.MAJOR;
    public static final int MINOR = GtkLoader.MINOR;
    public static final int MICRO = GtkLoader.MICRO;
    public static final Gtk Gtk2 = GtkLoader.isGtk2 ? new Gtk2() : new Gtk3();
    public static final Gtk3 Gtk3 = GtkLoader.isGtk2 ? null : (Gtk3)Gtk2;
    public static final boolean isGtk2 = GtkLoader.isGtk2;
    public static final boolean isGtk3 = GtkLoader.isGtk3;
    public static final boolean isLoaded = GtkLoader.isLoaded;
    public static final boolean alreadyRunningGTK = GtkLoader.alreadyRunningGTK;
    public static final Function gtk_status_icon_position_menu = GtkLoader.gtk_status_icon_position_menu;

    public boolean gtk_init_check(int var1);

    public GMainLoop g_main_loop_new(Pointer var1, boolean var2);

    public void g_main_loop_run(GMainLoop var1);

    public void g_main_loop_quit(GMainLoop var1);

    public GMainContext g_main_loop_get_context(GMainLoop var1);

    public void g_main_context_invoke(GMainContext var1, FuncCallback var2, Pointer var3);

    public Pointer gtk_menu_new();

    public void gtk_menu_item_set_submenu(Pointer var1, Pointer var2);

    public Pointer gtk_separator_menu_item_new();

    public Pointer gtk_image_new_from_file(String var1);

    public void gtk_check_menu_item_set_active(Pointer var1, boolean var2);

    public Pointer gtk_image_menu_item_new_with_mnemonic(String var1);

    public Pointer gtk_check_menu_item_new_with_mnemonic(String var1);

    public void gtk_image_menu_item_set_image(Pointer var1, Pointer var2);

    public void gtk_image_menu_item_set_always_show_image(Pointer var1, boolean var2);

    public Pointer gtk_status_icon_new();

    public Pointer gdk_get_default_root_window();

    public Pointer gdk_screen_get_default();

    public double gdk_screen_get_resolution(Pointer var1);

    public void gtk_status_icon_set_from_file(Pointer var1, String var2);

    public void gtk_status_icon_set_visible(Pointer var1, boolean var2);

    public void gtk_status_icon_set_tooltip_text(Pointer var1, String var2);

    public void gtk_status_icon_set_title(Pointer var1, String var2);

    public void gtk_status_icon_set_name(Pointer var1, String var2);

    public void gtk_menu_popup(Pointer var1, Pointer var2, Pointer var3, Function var4, Pointer var5, int var6, int var7);

    public void gtk_menu_item_set_label(Pointer var1, String var2);

    public void gtk_menu_shell_append(Pointer var1, Pointer var2);

    public void gtk_widget_set_sensitive(Pointer var1, boolean var2);

    public void gtk_widget_show_all(Pointer var1);

    public void gtk_container_remove(Pointer var1, Pointer var2);

    public void gtk_widget_destroy(Pointer var1);

    public Pointer gtk_settings_get_for_screen(Pointer var1);

    public Pointer gtk_settings_get_default();

    public GtkStyle gtk_rc_get_style(Pointer var1);

    public void gtk_container_add(Pointer var1, Pointer var2);

    public Pointer gtk_bin_get_child(Pointer var1);

    public Pointer gtk_label_get_layout(Pointer var1);

    public void pango_layout_get_pixel_extents(Pointer var1, Pointer var2, Pointer var3);

    public void gtk_widget_realize(Pointer var1);

    public Pointer gtk_offscreen_window_new();

    public void gtk_widget_size_request(Pointer var1, Pointer var2);

    public Pointer gtk_image_menu_item_new_from_stock(String var1, Pointer var2);

    @Deprecated
    public boolean gtk_show_uri(Pointer var1, String var2, int var3, Pointer var4);

    public void gtk_widget_set_tooltip_text(Pointer var1, String var2);

    public Pointer gdk_display_get_default();
}

