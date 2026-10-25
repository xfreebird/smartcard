#ifndef CPCSC_H
#include <stdint.h>
#define CPCSC_H

// PCSC types re-declared (bypassing the system modulemap which is !swift)
typedef unsigned long SCARDCONTEXT;
typedef unsigned long SCARDHANDLE;
typedef int LONG;
typedef unsigned long DWORD;
typedef DWORD *LPDWORD;
typedef SCARDCONTEXT *LPSCARDCONTEXT;
typedef SCARDHANDLE *LPSCARDHANDLE;

typedef struct {
    DWORD dwProtocol;
    DWORD cbPciLength;
} SCARD_IO_REQUEST;

// PCSC function prototypes (from /System/Library/Frameworks/PCSC.framework)
extern LONG SCardEstablishContext(DWORD dwScope, const void *pvReserved1,
    const void *pvReserved2, LPSCARDCONTEXT phContext);
extern LONG SCardReleaseContext(SCARDCONTEXT hContext);
extern LONG SCardListReaders(SCARDCONTEXT hContext, const char *mszGroups,
    char *mszReaders, LPDWORD pcchReaders);
extern LONG SCardConnect(SCARDCONTEXT hContext, const char *szReader,
    DWORD dwShareMode, DWORD dwPreferredProtocols, LPSCARDHANDLE phCard,
    LPDWORD pdwActiveProtocol);
extern LONG SCardDisconnect(SCARDHANDLE hCard, DWORD dwDisposition);
extern LONG SCardTransmit(SCARDHANDLE hCard, const void *pioSendPci,
    const unsigned char *pbSendBuffer, DWORD cbSendLength,
    void *pioRecvPci, unsigned char *pbRecvBuffer, LPDWORD pcbRecvLength);

// Thin wrappers for Swift
extern int32_t c_scard_establish(uint32_t scope, void *ctx_out);
extern int32_t c_scard_list_readers(void *ctx, char *readers, uint32_t *len);
extern int32_t c_scard_connect(void *ctx, const char *reader, uint32_t share, uint32_t proto, void *card_out, uint32_t *active_proto);
extern int32_t c_scard_disconnect(void *card, uint32_t disposition);
extern int32_t c_scard_release(void *ctx);
extern int32_t c_scard_transmit(void *card, const uint8_t *send, uint32_t send_len, uint8_t *recv, uint32_t *recv_len);

#endif

// AES-256 wrappers
extern int32_t c_aes256_ecb_encrypt(const uint8_t *key, uint32_t key_len, const uint8_t *in, uint8_t *out);
extern int32_t c_aes256_cbc_encrypt(const uint8_t *key, uint32_t key_len, const uint8_t *iv, const uint8_t *in, uint32_t in_len, uint8_t *out, uint32_t *out_len);
extern int32_t c_aes256_cbc_decrypt(const uint8_t *key, uint32_t key_len, const uint8_t *iv, const uint8_t *in, uint32_t in_len, uint8_t *out, uint32_t *out_len);

// AES-256 CMAC (RFC 4493)
extern void c_aes256_cmac(const uint8_t *key, uint32_t key_len, const uint8_t *msg, uint32_t msg_len, uint8_t *out);
extern int32_t c_scard_reconnect(void *card, uint32_t share, uint32_t proto, uint32_t disposition, uint32_t *active_proto);
extern LONG SCardReconnect(SCARDHANDLE hCard, DWORD dwShareMode, DWORD dwPreferredProtocols, DWORD dwInitialization, LPDWORD pdwActiveProtocol);
