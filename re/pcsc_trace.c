/*
 * pcsc_trace.dylib — DYLD_INSERT_LIBRARIES interposer for PCSC.framework (v2).
 *
 * Logs smart card reader/card traffic (connects, status/ATR, APDU exchanges)
 * to $PCSC_TRACE_FILE in an explicitly chosen owner-private directory.
 *
 * PIN SAFETY: APDUs that may carry PINs (INS 0x20 VERIFY, 0x24 CHANGE
 * REFERENCE DATA, 0x2C RESET RETRY COUNTER, 0xDA/0xDB PUT/GET DATA) are
 * logged with the data field masked. The PIN never reaches the log.
 *
 * Mechanism (macOS two-level namespace requires the __interpose section —
 * plain same-name exports do NOT shadow two-level-bound references):
 *   - For each SCard* function: an {replacement, replacee} tuple in
 *     __DATA,__interpose. dyld rebinds every other image's references to
 *     the replacee onto our wrapper. The tuple's replacee pointer gives us
 *     the original function address; no dlsym(RTLD_NEXT) bootstrap needed.
 *   - dlsym is interposed the same way so that middleware which resolves
 *     SCard* pointers dynamically (bit4id "InitWinScard" loader) receives
 *     wrappers instead of originals. '_'-prefixed (Mach-O) names handled.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <stdarg.h>
#include <unistd.h>
#include <pthread.h>
#include <sys/time.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <dlfcn.h>
#include <PCSC/PCSC.h>

typedef struct {
    const void *replacement;
    const void *replacee;
} interpose_tuple_t;

#define INTERPOSE_TUPLE(sym, repl)                                             \
    static const interpose_tuple_t g_ip_##sym                                  \
        __attribute__((used, section("__DATA,__interpose"))) = {                \
            (const void *)(uintptr_t)&(repl),                                   \
            (const void *)(uintptr_t)&(sym),                                   \
    };                                                                         \
    static const void *g_orig_##sym(void) { return g_ip_##sym.replacee; }

/* ---------- logging ---------- */
static FILE *g_log;
static pthread_mutex_t g_mu = PTHREAD_MUTEX_INITIALIZER;
static double g_t0;

static double now_s(void) {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return tv.tv_sec + tv.tv_usec / 1e6 - g_t0;
}

static FILE *ensure_log(void) {
    if (!g_log) {
        const char *path = getenv("PCSC_TRACE_FILE");
        if (!path || path[0] != '/') return NULL;
        char *parent = strdup(path);
        if (!parent) return NULL;
        char *name = strrchr(parent, '/');
        if (!name || name == parent || !name[1]) { free(parent); return NULL; }
        *name++ = '\0';
        int directory = open(parent, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);
        struct stat st;
        if (directory < 0 || fstat(directory, &st) != 0 || st.st_uid != geteuid() || (st.st_mode & 0077)) {
            if (directory >= 0) close(directory);
            free(parent);
            return NULL;
        }
        int fd = openat(directory, name, O_WRONLY | O_APPEND | O_CREAT | O_NOFOLLOW | O_CLOEXEC, 0600);
        close(directory);
        free(parent);
        if (fd < 0) return NULL;
        if (fstat(fd, &st) != 0 || !S_ISREG(st.st_mode) || st.st_uid != geteuid() ||
            (st.st_mode & 0077) || st.st_nlink != 1) { close(fd); return NULL; }
        g_log = fdopen(fd, "a");
        if (!g_log) close(fd);
    }
    return g_log;
}

static void tlog(const char *fmt, ...) {
    pthread_mutex_lock(&g_mu);
    FILE *f = ensure_log();
    if (f) {
        fprintf(f, "[%10.6f] ", now_s());
        va_list ap;
        va_start(ap, fmt);
        vfprintf(f, fmt, ap);
        va_end(ap);
        fputc('\n', f);
        fflush(f);
    }
    pthread_mutex_unlock(&g_mu);
}

static void hex_out(FILE *f, const unsigned char *b, size_t n) {
    for (size_t i = 0; i < n; i++) fprintf(f, "%02X", b[i]);
}

/* Log an outgoing APDU, masking PIN-bearing commands. */
static void log_apdu_out(SCARDHANDLE h, const unsigned char *b, DWORD n) {
    pthread_mutex_lock(&g_mu);
    FILE *f = ensure_log();
    if (f) {
        fprintf(f, "[%10.6f] TX hCard=%#llx len=%lu APDU=",
                now_s(), (unsigned long long)h, (unsigned long)n);
        if (!b || n == 0) {
            fprintf(f, "<empty>");
        } else {
            size_t hdr = n < 5 ? n : 5;
            hex_out(f, b, hdr);
            int secret = (n >= 2) && (b[1] == 0x20 || b[1] == 0x24 || b[1] == 0x2C ||
                                     b[1] == 0xDA || b[1] == 0xDB);
            if (secret)
                fprintf(f, "..[PIN-DATA MASKED, %lu bytes]", (unsigned long)(n - hdr));
            else
                hex_out(f, b + hdr, n - hdr);
        }
        fputc('\n', f);
        fflush(f);
    }
    pthread_mutex_unlock(&g_mu);
}

static void log_bytes(const char *tag, SCARDHANDLE h, const unsigned char *b, DWORD n) {
    pthread_mutex_lock(&g_mu);
    FILE *f = ensure_log();
    if (f) {
        fprintf(f, "[%10.6f] %s hCard=%#llx len=%lu bytes=",
                now_s(), tag, (unsigned long long)h, (unsigned long)n);
        if (b && n) hex_out(f, b, n);
        fputc('\n', f);
        fflush(f);
    }
    pthread_mutex_unlock(&g_mu);
}

/* ---------- wrapper forward declarations ---------- */
static LONG trace_SCardEstablishContext(DWORD, LPCVOID, LPCVOID, LPSCARDCONTEXT);
static LONG trace_SCardListReaders(SCARDCONTEXT, LPCSTR, LPSTR, LPDWORD);
static LONG trace_SCardConnect(SCARDCONTEXT, LPCSTR, DWORD, DWORD, LPSCARDHANDLE, LPDWORD);
static LONG trace_SCardReconnect(SCARDHANDLE, DWORD, DWORD, DWORD, LPDWORD);
static LONG trace_SCardDisconnect(SCARDHANDLE, DWORD);
static LONG trace_SCardBeginTransaction(SCARDHANDLE);
static LONG trace_SCardEndTransaction(SCARDHANDLE, DWORD);
static LONG trace_SCardStatus(SCARDHANDLE, LPSTR, LPDWORD, LPDWORD, LPDWORD, LPBYTE, LPDWORD);
static LONG trace_SCardGetAttrib(SCARDHANDLE, DWORD, LPBYTE, LPDWORD);
static LONG trace_SCardControl(SCARDHANDLE, DWORD, LPCVOID, DWORD, LPVOID, DWORD, LPDWORD);
static LONG trace_SCardTransmit(SCARDHANDLE, const SCARD_IO_REQUEST *, LPCBYTE, DWORD,
                                SCARD_IO_REQUEST *, LPBYTE, LPDWORD);
static void *trace_dlsym(void *handle, const char *name);

/* ---------- dlsym interposition ---------- */
INTERPOSE_TUPLE(dlsym, trace_dlsym)

static void *wrapper_for(const char *name) {
    if (!name) return NULL;
    while (*name == '_') name++; /* tolerate Mach-O mangled names */
    if (!strcmp(name, "SCardEstablishContext")) return (void *)(uintptr_t)&trace_SCardEstablishContext;
    if (!strcmp(name, "SCardListReaders"))      return (void *)(uintptr_t)&trace_SCardListReaders;
    if (!strcmp(name, "SCardConnect"))          return (void *)(uintptr_t)&trace_SCardConnect;
    if (!strcmp(name, "SCardReconnect"))        return (void *)(uintptr_t)&trace_SCardReconnect;
    if (!strcmp(name, "SCardDisconnect"))       return (void *)(uintptr_t)&trace_SCardDisconnect;
    if (!strcmp(name, "SCardBeginTransaction")) return (void *)(uintptr_t)&trace_SCardBeginTransaction;
    if (!strcmp(name, "SCardEndTransaction"))   return (void *)(uintptr_t)&trace_SCardEndTransaction;
    if (!strcmp(name, "SCardStatus"))           return (void *)(uintptr_t)&trace_SCardStatus;
    if (!strcmp(name, "SCardGetAttrib"))        return (void *)(uintptr_t)&trace_SCardGetAttrib;
    if (!strcmp(name, "SCardControl"))          return (void *)(uintptr_t)&trace_SCardControl;
    if (!strcmp(name, "SCardTransmit"))         return (void *)(uintptr_t)&trace_SCardTransmit;
    return NULL;
}

static void *trace_dlsym(void *handle, const char *name) {
    void *wrapped = wrapper_for(name);
    if (wrapped) {
        tlog("dlsym(\"%s\") -> wrapped", name);
        return wrapped;
    }
    static void *(*real_dlsym)(void *, const char *);
    if (!real_dlsym)
        real_dlsym = (void *(*)(void *, const char *))(uintptr_t)g_orig_dlsym();
    return real_dlsym(handle, name);
}

/* ---------- SCard wrappers ---------- */

INTERPOSE_TUPLE(SCardEstablishContext, trace_SCardEstablishContext)
static LONG trace_SCardEstablishContext(DWORD scope, LPCVOID a, LPCVOID b, LPSCARDCONTEXT ctx) {
    static LONG (*orig)(DWORD, LPCVOID, LPCVOID, LPSCARDCONTEXT);
    if (!orig) orig = (LONG (*)(DWORD, LPCVOID, LPCVOID, LPSCARDCONTEXT))(uintptr_t)g_orig_SCardEstablishContext();
    LONG r = orig(scope, a, b, ctx);
    tlog("SCardEstablishContext -> 0x%08lX ctx=%#llx",
         (unsigned long)r, ctx ? (unsigned long long)*ctx : 0ULL);
    return r;
}

INTERPOSE_TUPLE(SCardListReaders, trace_SCardListReaders)
static LONG trace_SCardListReaders(SCARDCONTEXT ctx, LPCSTR groups, LPSTR readers, LPDWORD size) {
    static LONG (*orig)(SCARDCONTEXT, LPCSTR, LPSTR, LPDWORD);
    if (!orig) orig = (LONG (*)(SCARDCONTEXT, LPCSTR, LPSTR, LPDWORD))(uintptr_t)g_orig_SCardListReaders();
    LONG r = orig(ctx, groups, readers, size);
    tlog("SCardListReaders -> 0x%08lX", (unsigned long)r);
    if (r == SCARD_S_SUCCESS && readers && size && *size)
        tlog("SCardListReaders readers: %.*s", (int)(*size - 1), readers);
    return r;
}

INTERPOSE_TUPLE(SCardConnect, trace_SCardConnect)
static LONG trace_SCardConnect(SCARDCONTEXT ctx, LPCSTR reader, DWORD share, DWORD proto,
                               LPSCARDHANDLE card, LPDWORD active) {
    static LONG (*orig)(SCARDCONTEXT, LPCSTR, DWORD, DWORD, LPSCARDHANDLE, LPDWORD);
    if (!orig) orig = (LONG (*)(SCARDCONTEXT, LPCSTR, DWORD, DWORD, LPSCARDHANDLE, LPDWORD))(uintptr_t)g_orig_SCardConnect();
    LONG r = orig(ctx, reader, share, proto, card, active);
    tlog("SCardConnect(reader=\"%s\", share=%lu, proto=%lu) -> 0x%08lX hCard=%#llx active=%lu",
         reader ? reader : "?", (unsigned long)share, (unsigned long)proto,
         (unsigned long)r, card ? (unsigned long long)*card : 0ULL,
         active ? (unsigned long)*active : 0UL);
    return r;
}

INTERPOSE_TUPLE(SCardReconnect, trace_SCardReconnect)
static LONG trace_SCardReconnect(SCARDHANDLE h, DWORD share, DWORD proto, DWORD disp, LPDWORD po) {
    static LONG (*orig)(SCARDHANDLE, DWORD, DWORD, DWORD, LPDWORD);
    if (!orig) orig = (LONG (*)(SCARDHANDLE, DWORD, DWORD, DWORD, LPDWORD))(uintptr_t)g_orig_SCardReconnect();
    LONG r = orig(h, share, proto, disp, po);
    tlog("SCardReconnect(hCard=%#llx) -> 0x%08lX", (unsigned long long)h, (unsigned long)r);
    return r;
}

INTERPOSE_TUPLE(SCardDisconnect, trace_SCardDisconnect)
static LONG trace_SCardDisconnect(SCARDHANDLE h, DWORD disp) {
    tlog("SCardDisconnect(hCard=%#llx, disp=%lu)", (unsigned long long)h, (unsigned long)disp);
    static LONG (*orig)(SCARDHANDLE, DWORD);
    if (!orig) orig = (LONG (*)(SCARDHANDLE, DWORD))(uintptr_t)g_orig_SCardDisconnect();
    return orig(h, disp);
}

INTERPOSE_TUPLE(SCardBeginTransaction, trace_SCardBeginTransaction)
static LONG trace_SCardBeginTransaction(SCARDHANDLE h) {
    tlog("SCardBeginTransaction(hCard=%#llx)", (unsigned long long)h);
    static LONG (*orig)(SCARDHANDLE);
    if (!orig) orig = (LONG (*)(SCARDHANDLE))(uintptr_t)g_orig_SCardBeginTransaction();
    return orig(h);
}

INTERPOSE_TUPLE(SCardEndTransaction, trace_SCardEndTransaction)
static LONG trace_SCardEndTransaction(SCARDHANDLE h, DWORD disp) {
    tlog("SCardEndTransaction(hCard=%#llx)", (unsigned long long)h);
    static LONG (*orig)(SCARDHANDLE, DWORD);
    if (!orig) orig = (LONG (*)(SCARDHANDLE, DWORD))(uintptr_t)g_orig_SCardEndTransaction();
    return orig(h, disp);
}

INTERPOSE_TUPLE(SCardStatus, trace_SCardStatus)
static LONG trace_SCardStatus(SCARDHANDLE h, LPSTR reader, LPDWORD reader_len, LPDWORD state,
                              LPDWORD proto, LPBYTE atr, LPDWORD atr_len) {
    static LONG (*orig)(SCARDHANDLE, LPSTR, LPDWORD, LPDWORD, LPDWORD, LPBYTE, LPDWORD);
    if (!orig) orig = (LONG (*)(SCARDHANDLE, LPSTR, LPDWORD, LPDWORD, LPDWORD, LPBYTE, LPDWORD))(uintptr_t)g_orig_SCardStatus();
    LONG r = orig(h, reader, reader_len, state, proto, atr, atr_len);
    tlog("SCardStatus(hCard=%#llx) -> 0x%08lX state=%#lx proto=%#lx",
         (unsigned long long)h, (unsigned long)r,
         state ? (unsigned long)*state : 0UL, proto ? (unsigned long)*proto : 0UL);
    if (r == SCARD_S_SUCCESS && atr && atr_len && *atr_len)
        log_bytes("ATR", h, (const unsigned char *)atr, *atr_len);
    return r;
}

INTERPOSE_TUPLE(SCardGetAttrib, trace_SCardGetAttrib)
static LONG trace_SCardGetAttrib(SCARDHANDLE h, DWORD id, LPBYTE buf, LPDWORD len) {
    static LONG (*orig)(SCARDHANDLE, DWORD, LPBYTE, LPDWORD);
    if (!orig) orig = (LONG (*)(SCARDHANDLE, DWORD, LPBYTE, LPDWORD))(uintptr_t)g_orig_SCardGetAttrib();
    LONG r = orig(h, id, buf, len);
    tlog("SCardGetAttrib(hCard=%#llx, id=%#lx) -> 0x%08lX len=%lu",
         (unsigned long long)h, (unsigned long)id, (unsigned long)r,
         len ? (unsigned long)*len : 0UL);
    return r;
}

INTERPOSE_TUPLE(SCardControl, trace_SCardControl)
static LONG trace_SCardControl(SCARDHANDLE h, DWORD code, LPCVOID in, DWORD in_len,
                                LPVOID out, DWORD out_len, LPDWORD out_done) {
    static LONG (*orig)(SCARDHANDLE, DWORD, LPCVOID, DWORD, LPVOID, DWORD, LPDWORD);
    if (!orig) orig = (LONG (*)(SCARDHANDLE, DWORD, LPCVOID, DWORD, LPVOID, DWORD, LPDWORD))(uintptr_t)g_orig_SCardControl();
    LONG r = orig(h, code, in, in_len, out, out_len, out_done);
    tlog("SCardControl(hCard=%#llx, code=%#lx, in_len=%lu) -> 0x%08lX",
         (unsigned long long)h, (unsigned long)code, (unsigned long)in_len, (unsigned long)r);
    if (in && in_len) log_bytes("CTL_IN", h, (const unsigned char *)in, in_len);
    if (out && out_done && *out_done) log_bytes("CTL_OUT", h, (const unsigned char *)out, *out_done);
    return r;
}

INTERPOSE_TUPLE(SCardTransmit, trace_SCardTransmit)
static LONG trace_SCardTransmit(SCARDHANDLE h, const SCARD_IO_REQUEST *send_pci, LPCBYTE send,
                                DWORD send_len, SCARD_IO_REQUEST *recv_pci, LPBYTE recv, LPDWORD recv_len) {
    static LONG (*orig)(SCARDHANDLE, const SCARD_IO_REQUEST *, LPCBYTE, DWORD, SCARD_IO_REQUEST *, LPBYTE, LPDWORD);
    if (!orig) orig = (LONG (*)(SCARDHANDLE, const SCARD_IO_REQUEST *, LPCBYTE, DWORD, SCARD_IO_REQUEST *, LPBYTE, LPDWORD))(uintptr_t)g_orig_SCardTransmit();
    log_apdu_out(h, (const unsigned char *)send, send_len);
    LONG r = orig(h, send_pci, send, send_len, recv_pci, recv, recv_len);
    if (r == SCARD_S_SUCCESS)
        log_bytes("RX", h, (const unsigned char *)recv, recv_len ? *recv_len : 0);
    else
        tlog("SCardTransmit(hCard=%#llx) FAILED 0x%08lX", (unsigned long long)h, (unsigned long)r);
    return r;
}

/* ---------- constructor ---------- */
__attribute__((constructor)) static void pcsc_trace_ctor(void) {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    g_t0 = tv.tv_sec + tv.tv_usec / 1e6;
    tlog("=== pcsc_trace v2 loaded pid=%d ===", (int)getpid());
    if (g_orig_SCardTransmit() == (const void *)(uintptr_t)&trace_SCardTransmit)
        tlog("ERROR: SCardTransmit tuple self-referential");
    if (g_orig_dlsym() == (const void *)(uintptr_t)&trace_dlsym)
        tlog("ERROR: dlsym tuple self-referential");
    tlog("orig Transmit=%p wrapped=%p",
         g_orig_SCardTransmit(), (const void *)(uintptr_t)&trace_SCardTransmit);
}
