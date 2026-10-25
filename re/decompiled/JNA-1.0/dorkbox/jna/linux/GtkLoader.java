/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.sun.jna.Function
 *  com.sun.jna.NativeLibrary
 *  dorkbox.os.OS
 *  dorkbox.updates.Updates
 *  org.slf4j.LoggerFactory
 */
package dorkbox.jna.linux;

import com.sun.jna.Function;
import com.sun.jna.NativeLibrary;
import dorkbox.jna.JNA;
import dorkbox.jna.linux.Gtk2;
import dorkbox.jna.linux.Gtk3;
import dorkbox.jna.linux.Gtk3VersionInfo;
import dorkbox.jna.linux.GtkCheck;
import dorkbox.jna.linux.GtkEventDispatch;
import dorkbox.jna.rendering.RenderProvider;
import dorkbox.os.OS;
import dorkbox.updates.Updates;
import org.slf4j.LoggerFactory;

public class GtkLoader {
    static boolean isGtk2;
    static boolean isGtk3;
    static boolean isLoaded;
    static boolean alreadyRunningGTK;
    static Function gtk_status_icon_position_menu;
    static int MAJOR;
    static int MINOR;
    static int MICRO;
    private static final NativeLibrary libraryReference;

    public static String getVersion() {
        return JNA.getVersion();
    }

    static {
        NativeLibrary library;
        boolean shouldLoadGtk;
        int micro;
        int minor;
        int major;
        boolean _isLoaded;
        boolean _isGtk2;
        block23: {
            Function gtk_main_level;
            String gtk2LibName;
            boolean _alreadyRunningGTK;
            block22: {
                gtk_status_icon_position_menu = null;
                Updates.INSTANCE.add(GtkLoader.class, "d712ab5998d742a1bc96ca2f7be197ce", GtkLoader.getVersion());
                boolean forceGtk2 = GtkEventDispatch.FORCE_GTK2;
                boolean preferGtk3 = !forceGtk2 && GtkEventDispatch.PREFER_GTK3;
                _isGtk2 = false;
                _isLoaded = false;
                _alreadyRunningGTK = false;
                major = 0;
                minor = 0;
                micro = 0;
                boolean bl = shouldLoadGtk = !OS.INSTANCE.isWindows() && !OS.INSTANCE.isMacOsX();
                if (!shouldLoadGtk) {
                    _isLoaded = true;
                }
                gtk2LibName = "gtk-x11-2.0";
                String gtk3LibName = "libgtk-3.so.0";
                library = null;
                if (!(_isLoaded || !forceGtk2 && preferGtk3)) {
                    block21: {
                        try {
                            library = JNA.register(gtk2LibName, Gtk2.class);
                            _isGtk2 = true;
                            major = library.getGlobalVariableAddress("gtk_major_version").getInt(0L);
                            minor = library.getGlobalVariableAddress("gtk_minor_version").getInt(0L);
                            micro = library.getGlobalVariableAddress("gtk_micro_version").getInt(0L);
                            gtk_status_icon_position_menu = library.getFunction("gtk_status_icon_position_menu");
                            gtk_main_level = library.getFunction("gtk_main_level");
                            _alreadyRunningGTK = gtk_main_level.invokeInt(null) != 0;
                            _isLoaded = true;
                            if (GtkEventDispatch.DEBUG) {
                                LoggerFactory.getLogger(GtkLoader.class).debug("GTK: {}", (Object)gtk2LibName);
                            }
                        }
                        catch (Throwable e) {
                            if (library != null) {
                                library.close();
                            }
                            if (!GtkEventDispatch.DEBUG) break block21;
                            LoggerFactory.getLogger(GtkLoader.class).debug("Error loading library", e);
                        }
                    }
                    if (forceGtk2) {
                        _isLoaded = true;
                    }
                }
                if (!_isLoaded) {
                    try {
                        library = JNA.register(gtk3LibName, Gtk3VersionInfo.class);
                        Gtk3VersionInfo version = new Gtk3VersionInfo();
                        major = version.gtk_get_major_version();
                        minor = version.gtk_get_minor_version();
                        micro = version.gtk_get_micro_version();
                        library.close();
                        library = null;
                        library = JNA.register(gtk3LibName, Gtk3.class);
                        gtk_status_icon_position_menu = library.getFunction("gtk_status_icon_position_menu");
                        Function gtk_main_level2 = library.getFunction("gtk_main_level");
                        _alreadyRunningGTK = gtk_main_level2.invokeInt(null) != 0;
                        _isLoaded = true;
                        if (GtkEventDispatch.DEBUG) {
                            LoggerFactory.getLogger(GtkLoader.class).debug("GTK: {}", (Object)gtk3LibName);
                        }
                    }
                    catch (Throwable e) {
                        if (library != null) {
                            library.close();
                        }
                        if (!GtkEventDispatch.DEBUG) break block22;
                        LoggerFactory.getLogger(GtkLoader.class).debug("Error loading library.", e);
                    }
                }
            }
            if (!_isLoaded) {
                try {
                    library = JNA.register(gtk2LibName, Gtk2.class);
                    _isGtk2 = true;
                    major = library.getGlobalVariableAddress("gtk_major_version").getInt(0L);
                    minor = library.getGlobalVariableAddress("gtk_minor_version").getInt(0L);
                    micro = library.getGlobalVariableAddress("gtk_micro_version").getInt(0L);
                    gtk_status_icon_position_menu = Function.getFunction((String)gtk2LibName, (String)"gtk_status_icon_position_menu");
                    gtk_main_level = library.getFunction("gtk_main_level");
                    _alreadyRunningGTK = gtk_main_level.invokeInt(null) != 0;
                    _isLoaded = true;
                    if (GtkEventDispatch.DEBUG) {
                        LoggerFactory.getLogger(GtkLoader.class).debug("GTK: {}", (Object)gtk2LibName);
                    }
                }
                catch (Throwable e) {
                    if (library != null) {
                        library.close();
                    }
                    if (!GtkEventDispatch.DEBUG) break block23;
                    LoggerFactory.getLogger(GtkLoader.class).debug("Error loading library", e);
                }
            }
        }
        if (shouldLoadGtk && _isLoaded) {
            isLoaded = true;
            alreadyRunningGTK = _alreadyRunningGTK |= RenderProvider.alreadyRunning();
            isGtk2 = _isGtk2;
            isGtk3 = !_isGtk2;
            MAJOR = major;
            MINOR = minor;
            MICRO = micro;
        } else {
            isLoaded = false;
            alreadyRunningGTK = false;
            isGtk2 = false;
            isGtk3 = false;
            MAJOR = 0;
            MINOR = 0;
            MICRO = 0;
        }
        GtkCheck.isGtk2 = isGtk2;
        GtkCheck.isGtk3 = isGtk3;
        GtkCheck.isGtkLoaded = isLoaded;
        GtkCheck.MAJOR = MAJOR;
        GtkCheck.MINOR = MINOR;
        GtkCheck.MICRO = MICRO;
        if (isGtk3) {
            Gtk3.loadMethods(library);
        }
        libraryReference = library;
        if (shouldLoadGtk && !_isLoaded) {
            throw new RuntimeException("We apologize for this, but we are unable to determine the GTK library is in use, or even if it is in use... Please create an issue for this and include your OS type and configuration.");
        }
    }
}

