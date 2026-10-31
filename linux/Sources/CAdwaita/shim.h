#ifndef MOLDSIGN_CADWAITA_SHIM_H
#define MOLDSIGN_CADWAITA_SHIM_H

// GTK 4 + libadwaita (which includes <gtk/gtk.h>, GIO and GLib).
// Minimum: GTK 4.12, libadwaita 1.5 (Ubuntu 24.04, Fedora 40, Debian 13, GNOME 46+ runtime).
#include <adwaita.h>
#include <dlfcn.h>

// Optional layout preference on newer libadwaita. Noble's 1.5 uses its native default.
static inline void moldsign_alert_prefer_wide(AdwAlertDialog *dialog) {
    typedef void (*Setter)(AdwAlertDialog *, gboolean);
    Setter setter = (Setter)dlsym(RTLD_DEFAULT, "adw_alert_dialog_set_prefer_wide_layout");
    if (setter) setter(dialog, TRUE);
}

#endif
