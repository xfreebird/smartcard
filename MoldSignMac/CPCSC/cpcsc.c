#include "cpcsc.h"
#include <string.h>

int32_t c_scard_establish(uint32_t scope, void *ctx_out) {
    SCARDCONTEXT ctx = 0;
    LONG rv = SCardEstablishContext(scope, NULL, NULL, &ctx);
    *(SCARDCONTEXT*)ctx_out = ctx;
    return rv;
}

int32_t c_scard_list_readers(void *ctx, char *readers, uint32_t *len) {
    SCARDCONTEXT c = *(SCARDCONTEXT*)ctx;
    DWORD dw = *len;
    LONG rv = SCardListReaders(c, NULL, readers, &dw);
    *len = dw;
    return rv;
}

int32_t c_scard_connect(void *ctx, const char *reader, uint32_t share, uint32_t proto, void *card_out, uint32_t *active_proto) {
    SCARDCONTEXT c = *(SCARDCONTEXT*)ctx;
    SCARDHANDLE h = 0;
    DWORD p = 0;
    LONG rv = SCardConnect(c, reader, share, proto, &h, &p);
    *(SCARDHANDLE*)card_out = h;
    *active_proto = p;
    return rv;
}

int32_t c_scard_disconnect(void *card, uint32_t disposition) {
    SCARDHANDLE h = *(SCARDHANDLE*)card;
    return SCardDisconnect(h, disposition);
}

int32_t c_scard_release(void *ctx) {
    return SCardReleaseContext(*(SCARDCONTEXT*)ctx);
}

int32_t c_scard_transmit(void *card, const uint8_t *send, uint32_t send_len, uint8_t *recv, uint32_t *recv_len) {
    SCARDHANDLE h = *(SCARDHANDLE*)card;
    SCARD_IO_REQUEST send_pci;
    send_pci.dwProtocol = 2; // T=1
    send_pci.cbPciLength = sizeof(SCARD_IO_REQUEST);
    SCARD_IO_REQUEST recv_pci;
    recv_pci.dwProtocol = 0;
    recv_pci.cbPciLength = sizeof(SCARD_IO_REQUEST);
    DWORD dwRecv = *recv_len;
    LONG rv = SCardTransmit(h, &send_pci, send, send_len, &recv_pci, recv, &dwRecv);
    *recv_len = dwRecv;
    return rv;
}

#include <CommonCrypto/CommonCrypto.h>

int32_t c_aes256_ecb_encrypt(const uint8_t *key, uint32_t key_len, const uint8_t *in, uint8_t *out) {
    size_t outLen = 16;
    return CCCrypt(kCCEncrypt, kCCAlgorithmAES, kCCOptionECBMode,
                    key, key_len, NULL, in, 16, out, 16, &outLen);
}

int32_t c_aes256_cbc_encrypt(const uint8_t *key, uint32_t key_len, const uint8_t *iv, const uint8_t *in, uint32_t in_len, uint8_t *out, uint32_t *out_len) {
    size_t moved = 0;
    CCCryptorStatus st = CCCrypt(kCCEncrypt, kCCAlgorithmAES, 0,
                    key, key_len, iv, in, in_len, out, *out_len, &moved);
    *out_len = (uint32_t)moved;
    return st;
}

int32_t c_aes256_cbc_decrypt(const uint8_t *key, uint32_t key_len, const uint8_t *iv, const uint8_t *in, uint32_t in_len, uint8_t *out, uint32_t *out_len) {
    size_t moved = 0;
    CCCryptorStatus st = CCCrypt(kCCDecrypt, kCCAlgorithmAES, 0,
                    key, key_len, iv, in, in_len, out, *out_len, &moved);
    *out_len = (uint32_t)moved;
    return st;
}

void c_aes256_cmac(const uint8_t *key, uint32_t key_len, const uint8_t *msg, uint32_t msg_len, uint8_t *out) {
    uint8_t zero[16] = {0}, L[16], K1[16], K2[16], X[16] = {0}, Y[16], M_last[16], tmp[16];
    size_t outLen;

    // L = AES(K, 0^128) — use separate buffers!
    CCCrypt(kCCEncrypt, kCCAlgorithmAES, kCCOptionECBMode,
            key, key_len, NULL, zero, 16, L, 16, &outLen);

    // K1 = L << 1 (with R128 reduction)
    for (int i = 0; i < 15; i++) K1[i] = (L[i] << 1) | (L[i+1] >> 7);
    K1[15] = L[15] << 1;
    if (L[0] & 0x80) K1[15] ^= 0x87;

    // K2 = K1 << 1 (with R128 reduction)
    for (int i = 0; i < 15; i++) K2[i] = (K1[i] << 1) | (K1[i+1] >> 7);
    K2[15] = K1[15] << 1;
    if (K1[0] & 0x80) K2[15] ^= 0x87;

    uint32_t n = (msg_len + 15) / 16;
    if (n == 0) n = 1;

    int last_complete = (msg_len > 0 && msg_len % 16 == 0);

    if (last_complete) {
        for (int i = 0; i < 16; i++) M_last[i] = msg[(n-1)*16 + i] ^ K1[i];
    } else {
        memset(M_last, 0, 16);
        uint32_t rem = (msg_len % 16 == 0) ? 16 : msg_len % 16;
        for (uint32_t i = 0; i < rem && (n-1)*16 + i < msg_len; i++) M_last[i] = msg[(n-1)*16 + i];
        M_last[rem] = 0x80;
        for (int i = 0; i < 16; i++) M_last[i] ^= K2[i];
    }

    for (uint32_t i = 0; i < n - 1; i++) {
        for (int j = 0; j < 16; j++) Y[j] = X[j] ^ msg[i*16 + j];
        CCCrypt(kCCEncrypt, kCCAlgorithmAES, kCCOptionECBMode,
                key, key_len, NULL, Y, 16, X, 16, &outLen);
    }

    for (int j = 0; j < 16; j++) Y[j] = X[j] ^ M_last[j];
    CCCrypt(kCCEncrypt, kCCAlgorithmAES, kCCOptionECBMode,
            key, key_len, NULL, Y, 16, out, 16, &outLen);
}
int32_t c_scard_reconnect(void *card, uint32_t share, uint32_t proto, uint32_t disposition, uint32_t *active_proto) {
    SCARDHANDLE h = *(SCARDHANDLE*)card;
    DWORD p = 0;
    LONG rv = SCardReconnect(h, share, proto, disposition, &p);
    *active_proto = p;
    return rv;
}
