#include "CSentryRuntime.h"
#include "sentry.h"
#include <dlfcn.h>
#include <stdatomic.h>
#include <time.h>
#include <string.h>

// Resolve against the pinned public SDK header. Missing SDKs leave local development
// usable; distribution packaging always installs the library beside the application.
#define SDK(name) static __typeof__(&name) p_##name
SDK(sentry_options_new);
SDK(sentry_options_set_backend);
SDK(sentry_options_set_require_user_consent);
SDK(sentry_options_set_shutdown_timeout);
SDK(sentry_user_consent_give);
SDK(sentry_user_consent_revoke);
SDK(sentry_metrics_count);
SDK(sentry_metrics_distribution);
SDK(sentry_value_decref);
SDK(sentry_value_get_by_key);
SDK(sentry_value_get_by_index);
SDK(sentry_value_get_length);
SDK(sentry_value_set_by_key);
SDK(sentry_value_new_string);
SDK(sentry_value_as_string);
SDK(sentry_options_set_dsn);
SDK(sentry_options_set_release);
SDK(sentry_options_set_environment);
SDK(sentry_options_set_database_path);
SDK(sentry_options_set_before_send);
SDK(sentry_value_remove_by_key);
SDK(sentry_options_set_max_breadcrumbs);
SDK(sentry_options_set_auto_session_tracking);
SDK(sentry_options_set_symbolize_stacktraces);
SDK(sentry_options_set_traces_sample_rate);
SDK(sentry_init);
SDK(sentry_close);
SDK(sentry_flush);
SDK(sentry_value_new_event);
SDK(sentry_value_new_exception);
SDK(sentry_value_set_stacktrace);
SDK(sentry_event_add_exception);
SDK(sentry_capture_event);
SDK(sentry_value_new_null);
SDK(sentry_transaction_context_new);
SDK(sentry_transaction_start);
SDK(sentry_transaction_finish);
static void *library_handle;
static int initialized;
static atomic_int crash_allowed;
static atomic_int metrics_allowed;
static atomic_int launch_recorded;
static struct timespec session_start;
static sentry_value_t sanitize(sentry_value_t event, sentry_hint_t *hint, void *data)
{
    (void)hint; (void)data;
    const char *kind = p_sentry_value_as_string(p_sentry_value_get_by_key(event, "type"));
    int transaction = kind && strcmp(kind, "transaction") == 0;
    if (!(transaction ? atomic_load(&metrics_allowed) : atomic_load(&crash_allowed))) {
        p_sentry_value_decref(event); return p_sentry_value_new_null();
    }
    p_sentry_value_remove_by_key(event, "threads");
    sentry_value_t exceptions = p_sentry_value_get_by_key(p_sentry_value_get_by_key(event, "exception"), "values");
    for (size_t i = 0; i < p_sentry_value_get_length(exceptions); i++) {
        sentry_value_t exception = p_sentry_value_get_by_index(exceptions, i);
        // Signal/exception messages cannot include application values.
        p_sentry_value_set_by_key(exception, "value", p_sentry_value_new_string("Desktop application diagnostic"));
        sentry_value_t stack = p_sentry_value_get_by_key(exception, "stacktrace");
        p_sentry_value_remove_by_key(stack, "registers");
        sentry_value_t frames = p_sentry_value_get_by_key(stack, "frames");
        for (size_t j = 0; j < p_sentry_value_get_length(frames); j++) {
            sentry_value_t frame = p_sentry_value_get_by_index(frames, j);
            p_sentry_value_remove_by_key(frame, "vars");
            p_sentry_value_remove_by_key(frame, "abs_path");
        }
    }
    const char *keys[] = {"user", "request", "breadcrumbs", "extra", "server_name", "contexts"};
    for (unsigned i = 0; i < sizeof(keys) / sizeof(keys[0]); i++) p_sentry_value_remove_by_key(event, keys[i]);
    return event;
}
#define LOAD(name) do { p_##name = (__typeof__(p_##name))dlsym(library_handle, #name); \
    if (!p_##name) { dlclose(library_handle); library_handle = 0; return 0; } } while (0)

int ms_sentry_start(const char *library, const char *dsn, const char *release,
    const char *environment, const char *database, int verification, int crashes, int metrics)
{
    if (initialized) return 1;
    library_handle = dlopen(library, RTLD_NOW | RTLD_LOCAL);
    if (!library_handle) return 0;
    LOAD(sentry_options_set_backend); LOAD(sentry_options_set_require_user_consent);
    LOAD(sentry_options_set_shutdown_timeout); LOAD(sentry_user_consent_give); LOAD(sentry_user_consent_revoke);
    LOAD(sentry_metrics_count); LOAD(sentry_metrics_distribution); LOAD(sentry_value_decref); LOAD(sentry_value_get_by_key);
    LOAD(sentry_value_get_by_index); LOAD(sentry_value_get_length); LOAD(sentry_value_set_by_key); LOAD(sentry_value_new_string); LOAD(sentry_value_as_string);
    LOAD(sentry_options_new); LOAD(sentry_options_set_dsn);
    LOAD(sentry_options_set_release); LOAD(sentry_options_set_environment);
    LOAD(sentry_options_set_database_path); LOAD(sentry_options_set_before_send); LOAD(sentry_value_remove_by_key);
    LOAD(sentry_options_set_max_breadcrumbs); LOAD(sentry_options_set_auto_session_tracking);
    LOAD(sentry_options_set_traces_sample_rate); LOAD(sentry_options_set_symbolize_stacktraces); LOAD(sentry_init); LOAD(sentry_close);
    LOAD(sentry_flush); LOAD(sentry_value_new_event); LOAD(sentry_value_new_exception);
    LOAD(sentry_value_set_stacktrace); LOAD(sentry_event_add_exception);
    LOAD(sentry_capture_event); LOAD(sentry_value_new_null);
    LOAD(sentry_transaction_context_new); LOAD(sentry_transaction_start);
    LOAD(sentry_transaction_finish);
    atomic_store(&crash_allowed, crashes);
    atomic_store(&metrics_allowed, metrics);
    sentry_options_t *options = p_sentry_options_new();
    if (!crashes) p_sentry_options_set_backend(options, NULL);
    p_sentry_options_set_require_user_consent(options, 1);
    p_sentry_options_set_shutdown_timeout(options, 0);
    p_sentry_options_set_dsn(options, dsn);
    p_sentry_options_set_release(options, release);
    p_sentry_options_set_environment(options, environment);
    p_sentry_options_set_database_path(options, database);
    p_sentry_options_set_before_send(options, sanitize, NULL);
    p_sentry_options_set_max_breadcrumbs(options, 0);
    p_sentry_options_set_auto_session_tracking(options, 0);
    p_sentry_options_set_symbolize_stacktraces(options, 1);
    p_sentry_options_set_traces_sample_rate(options, metrics ? (verification ? 1.0 : 0.1) : 0.0);
    initialized = p_sentry_init(options) == 0;
    clock_gettime(CLOCK_MONOTONIC, &session_start);
    if (initialized) p_sentry_user_consent_give();
    if (initialized && metrics) {
        if (!atomic_exchange(&launch_recorded, 1)) p_sentry_metrics_count("app.launch", 1, p_sentry_value_new_null());
        sentry_transaction_context_t *ctx = p_sentry_transaction_context_new("app.start", "app.lifecycle");
        sentry_transaction_t *tx = p_sentry_transaction_start(ctx, p_sentry_value_new_null());
        p_sentry_transaction_finish(tx);
    }
    return initialized;
}

// Deliberately accepts no dynamic payload: documents, PINs, reader identifiers,
// certificates and exception descriptions cannot cross this boundary.
static void capture(const char *code)
{
    if (!initialized || !atomic_load(&crash_allowed)) return;
    sentry_value_t event = p_sentry_value_new_event();
    sentry_value_t exception = p_sentry_value_new_exception("eSemnBunDiagnostic", code);
    p_sentry_value_set_stacktrace(exception, NULL, 0);
    p_sentry_event_add_exception(event, exception);
    p_sentry_capture_event(event);
}
void ms_sentry_failure(void) { capture("operation_failed"); }
int ms_sentry_verify(void)
{
    if (!initialized) return -1;
    capture("esemnbun-sentry-verification-linux");
    return p_sentry_flush(10000);
}
void ms_sentry_metric_operation(int failed)
{
    if (initialized && atomic_load(&metrics_allowed))
        p_sentry_metrics_count(failed ? "app.operation.failed" : "app.operation.completed", 1, p_sentry_value_new_null());
}
void ms_sentry_close(void)
{
    atomic_store(&crash_allowed, 0); atomic_store(&metrics_allowed, 0);
    if (initialized) { p_sentry_user_consent_revoke(); p_sentry_close(); initialized = 0; }
    // The in-process crash handler can retain internal pointers. Do not unload this library.
}

void ms_sentry_finish(void)
{
    if (!initialized) return;
    if (atomic_load(&metrics_allowed)) {
        struct timespec now; clock_gettime(CLOCK_MONOTONIC, &now);
        double seconds = (now.tv_sec - session_start.tv_sec) + (now.tv_nsec - session_start.tv_nsec) / 1000000000.0;
        p_sentry_metrics_distribution("app.session.duration", seconds, "second", p_sentry_value_new_null());
    }
    p_sentry_flush(2000); // Normal termination only, while consent is still granted.
    ms_sentry_close();
}
