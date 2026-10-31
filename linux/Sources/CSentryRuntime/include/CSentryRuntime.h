#pragma once
int ms_sentry_start(const char *library, const char *dsn, const char *release,
    const char *environment, const char *database, int verification, int crashes, int metrics);
void ms_sentry_failure(void);
void ms_sentry_metric_operation(int failed);
int ms_sentry_verify(void);
void ms_sentry_close(void);
void ms_sentry_finish(void);
