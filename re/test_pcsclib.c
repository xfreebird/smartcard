/*
 * test_pcsclib — validates that pcsc_trace.dylib intercepts PCSC calls.
 *
 * Two modes:
 *   ./test_direct   — built linking PCSC.framework directly (two-level refs)
 *   ./test_dlopen   — built with NO PCSC link; dlopen()+dlsym() only,
 *                     mimicking bit4id's "InitWinScard" dynamic loader.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <PCSC/PCSC.h>

#ifdef MODE_DLOPEN
#include <dlfcn.h>
typedef LONG (*fn_EstablishContext)(DWORD, LPCVOID, LPCVOID, LPSCARDCONTEXT);
typedef LONG (*fn_ReleaseContext)(SCARDCONTEXT);
typedef LONG (*fn_ListReaders)(SCARDCONTEXT, LPCSTR, LPSTR, LPDWORD);
typedef LONG (*fn_Connect)(SCARDCONTEXT, LPCSTR, DWORD, DWORD, LPSCARDHANDLE, LPDWORD);
typedef LONG (*n_Status)(SCARDHANDLE, LPSTR, LPDWORD, LPDWORD, LPDWORD, LPBYTE, LPDWORD);
typedef LONG (*n_Transmit)(SCARDHANDLE, const SCARD_IO_REQUEST *, LPCBYTE, DWORD,
                           SCARD_IO_REQUEST *, LPBYTE, LPDWORD);
typedef LONG (*fn_Disconnect)(SCARDHANDLE, DWORD);
static fn_EstablishContext p_Est;
static fn_ReleaseContext p_Rel;
static fn_ListReaders p_List;
static fn_Connect p_Conn;
static n_Status p_Stat;
static n_Transmit p_Trans;
static fn_Disconnect p_Disc;
#else
#define p_Est SCardEstablishContext
#define p_Rel SCardReleaseContext
#define p_List SCardListReaders
#define p_Conn SCardConnect
#define p_Stat SCardStatus
#define p_Trans SCardTransmit
#define p_Disc SCardDisconnect
#endif

int main(void) {
#ifdef MODE_DLOPEN
    const char *path = "/System/Library/Frameworks/PCSC.framework/PCSC";
    void *dl = dlopen(path, RTLD_NOW);
    if (!dl) {
        printf("dlopen failed: %s\n", dlerror());
        return 1;
    }
    printf("dlopen OK (%s)\n", path);
    /* macOS dlsym uses the leading underscore */
    p_Est = (fn_EstablishContext)dlsym(dl, "_SCardEstablishContext");
    p_Rel = (fn_ReleaseContext)dlsym(dl, "_SCardReleaseContext");
    p_List = (fn_ListReaders)dlsym(dl, "_SCardListReaders");
    p_Conn = (fn_Connect)dlsym(dl, "_SCardConnect");
    p_Stat = (n_Status)dlsym(dl, "_SCardStatus");
    p_Trans = (n_Transmit)dlsym(dl, "_SCardTransmit");
    p_Disc = (fn_Disconnect)dlsym(dl, "_SCardDisconnect");
    if (!p_Est || !p_Rel || !p_List || !p_Conn || !p_Stat || !p_Trans || !p_Disc) {
        printf("dlsym failed for some function: Est=%p List=%p Conn=%p Stat=%p Trans=%p\n",
               (void *)p_Est, (void *)p_List, (void *)p_Conn, (void *)p_Stat, (void *)p_Trans);
        return 2;
    }
    printf("all dlsym lookups OK\n");
#endif
    SCARDCONTEXT ctx = 0;
    LONG r = p_Est(SCARD_SCOPE_USER, NULL, NULL, &ctx);
    printf("EstablishContext -> %08lX\n", (unsigned long)r);
    if (r != SCARD_S_SUCCESS) return 1;

    DWORD n = 0;
    r = p_List(ctx, NULL, NULL, &n);
    printf("ListReaders(size) -> %08lX, n=%lu\n", (unsigned long)r, (unsigned long)n);
    if (r != SCARD_S_SUCCESS || n == 0) return 2;
    char *names = malloc(n);
    r = p_List(ctx, NULL, names, &n);
    if (r != SCARD_S_SUCCESS) return 3;
    char *reader = strdup(names);
    printf("reader: %s\n", reader);

    SCARDHANDLE h = 0;
    DWORD proto = 0;
    r = p_Conn(ctx, reader, SCARD_SHARE_SHARED, SCARD_PROTOCOL_T0 | SCARD_PROTOCOL_T1, &h, &proto);
    printf("Connect -> %08lX proto=%lu\n", (unsigned long)r, (unsigned long)proto);
    if (r != SCARD_S_SUCCESS) return 4;

    char rbuf[1024];
    DWORD rlen = sizeof(rbuf);
    DWORD state = 0, atrlen = 0, pro2 = 0;
    unsigned char atr[64];
    atrlen = sizeof(atr);
    r = p_Stat(h, rbuf, &rlen, &state, &pro2, atr, &atrlen);
    printf("Status -> %08lX state=%#lx ATRlen=%lu\n", (unsigned long)r,
           (unsigned long)state, (unsigned long)atrlen);
    if (r == SCARD_S_SUCCESS && atrlen) {
        printf("ATR: ");
        for (DWORD i = 0; i < atrlen; i++) printf("%02X", atr[i]);
        printf("\n");
    }

    /* harmless SELECT of the MF — no PIN involved */
    unsigned char sel[] = {0x00, 0xA4, 0x00, 0x0C, 0x02, 0x3F, 0x00};
    unsigned char rsp[512];
    DWORD rn = sizeof(rsp);
    SCARD_IO_REQUEST ri;
    ri.dwProtocol = proto;
    ri.cbPciLength = sizeof(SCARD_IO_REQUEST);
    r = p_Trans(h, &ri, sel, sizeof(sel), &ri, rsp, &rn);
    printf("Transmit SELECT MF -> %08lX, %lu bytes\n", (unsigned long)r, (unsigned long)rn);

    p_Disc(h, SCARD_LEAVE_CARD);
    p_Rel(ctx);
    printf("done\n");
    return 0;
}
