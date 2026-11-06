#if __has_include(<poppler.h>)
#include <poppler.h>
#else
// Some pkg-config graphs contain cyclic private dependencies; the public
// distribution include prefix still works when SwiftPM drops that flag set.
#include <poppler/glib/poppler.h>
#endif
