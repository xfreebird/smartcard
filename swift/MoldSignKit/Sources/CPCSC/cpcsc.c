#include "cpcsc.h"
#include <string.h>
#include <limits.h>

#if defined(__APPLE__)
#include <TargetConditionals.h>
#endif

// Backend selection
#if defined(__APPLE__) && TARGET_OS_OSX
#define CPCSC_HAS_PCSC 1
#include <PCSC/winscard.h>
#include <PCSC/wintypes.h>
#elif defined(__linux__)
#define CPCSC_HAS_PCSC 1
#include <PCSC/winscard.h>   // pcsc-lite (needs -I/usr/include/PCSC for its own includes)
#endif

#if !defined(__APPLE__) || defined(MOLDSIGN_OPENSSL)
#define CPCSC_OPENSSL 1
#include <openssl/evp.h>
#include <openssl/rsa.h>
#include <openssl/x509.h>
#include <openssl/pkcs12.h>
#include <openssl/ssl.h>
#include <openssl/err.h>
#include <openssl/provider.h>
#else
#include <CommonCrypto/CommonCrypto.h>
#endif

// MARK: - PC/SC

#ifdef CPCSC_HAS_PCSC

int32_t c_scard_available(void) { return 1; }

int32_t c_scard_establish(uint32_t scope, void *ctx_out) {
    SCARDCONTEXT ctx = 0;
    LONG rv = SCardEstablishContext(scope, NULL, NULL, &ctx);
    *(int64_t *)ctx_out = (int64_t)ctx;
    return (int32_t)rv;
}

int32_t c_scard_list_readers(void *ctx, char *readers, uint32_t *len) {
    SCARDCONTEXT c = (SCARDCONTEXT)*(int64_t *)ctx;
    DWORD dw = *len;
    LONG rv = SCardListReaders(c, NULL, readers, &dw);
    *len = (uint32_t)dw;
    return (int32_t)rv;
}

int32_t c_scard_connect(void *ctx, const char *reader, uint32_t share, uint32_t proto, void *card_out, uint32_t *active_proto) {
    SCARDCONTEXT c = (SCARDCONTEXT)*(int64_t *)ctx;
    SCARDHANDLE h = 0;
    DWORD p = 0;
    LONG rv = SCardConnect(c, reader, share, proto, &h, &p);
    *(int64_t *)card_out = (int64_t)h;
    *active_proto = (uint32_t)p;
    return (int32_t)rv;
}

int32_t c_scard_reconnect(void *card, uint32_t share, uint32_t proto, uint32_t disposition, uint32_t *active_proto) {
    SCARDHANDLE h = (SCARDHANDLE)*(int64_t *)card;
    DWORD p = 0;
    LONG rv = SCardReconnect(h, share, proto, disposition, &p);
    *active_proto = (uint32_t)p;
    return (int32_t)rv;
}

int32_t c_scard_disconnect(void *card, uint32_t disposition) {
    return (int32_t)SCardDisconnect((SCARDHANDLE)*(int64_t *)card, disposition);
}

int32_t c_scard_release(void *ctx) {
    return (int32_t)SCardReleaseContext((SCARDCONTEXT)*(int64_t *)ctx);
}

int32_t c_scard_transmit(void *card, const uint8_t *send, uint32_t send_len, uint8_t *recv, uint32_t *recv_len) {
    SCARDHANDLE h = (SCARDHANDLE)*(int64_t *)card;
    SCARD_IO_REQUEST send_pci;
    send_pci.dwProtocol = SCARD_PROTOCOL_T1;
    send_pci.cbPciLength = sizeof(SCARD_IO_REQUEST);
    SCARD_IO_REQUEST recv_pci;
    recv_pci.dwProtocol = 0;
    recv_pci.cbPciLength = sizeof(SCARD_IO_REQUEST);
    DWORD dwRecv = *recv_len;
    LONG rv = SCardTransmit(h, &send_pci, send, send_len, &recv_pci, recv, &dwRecv);
    *recv_len = (uint32_t)dwRecv;
    return (int32_t)rv;
}

int32_t c_scard_reader_state(void *ctx, const char *reader, uint32_t *state_out) {
    SCARDCONTEXT c = (SCARDCONTEXT)*(int64_t *)ctx;
    SCARD_READERSTATE rs;
    memset(&rs, 0, sizeof rs);
    rs.szReader = reader;
    rs.dwCurrentState = SCARD_STATE_UNAWARE;
    LONG rv = SCardGetStatusChange(c, 0, &rs, 1);
    *state_out = (uint32_t)rs.dwEventState;
    return (int32_t)rv;
}

int32_t c_scard_reader_atr(void *ctx, const char *reader, uint8_t *atr, uint32_t *atr_len) {
    SCARDCONTEXT c = (SCARDCONTEXT)*(int64_t *)ctx;
    SCARD_READERSTATE rs;
    memset(&rs, 0, sizeof rs);
    rs.szReader = reader;
    rs.dwCurrentState = SCARD_STATE_UNAWARE;
    LONG rv = SCardGetStatusChange(c, 0, &rs, 1);
    uint32_t n = 0;
    if (rv == SCARD_S_SUCCESS && (rs.dwEventState & SCARD_STATE_PRESENT)) {
        n = (uint32_t)rs.cbAtr;
        if (n > sizeof rs.rgbAtr) n = (uint32_t)sizeof rs.rgbAtr;
        if (n > *atr_len) n = *atr_len;
        memcpy(atr, rs.rgbAtr, n);
    }
    *atr_len = n;
    return (int32_t)rv;
}

#else  // iOS and other platforms without PC/SC: CryptoTokenKit is used instead

int32_t c_scard_available(void) { return 0; }
int32_t c_scard_establish(uint32_t scope, void *ctx_out) { (void)scope; *(int64_t *)ctx_out = 0; return -1; }
int32_t c_scard_list_readers(void *ctx, char *readers, uint32_t *len) { (void)ctx; (void)readers; *len = 0; return -1; }
int32_t c_scard_connect(void *ctx, const char *reader, uint32_t share, uint32_t proto, void *card_out, uint32_t *active_proto) {
    (void)ctx; (void)reader; (void)share; (void)proto; *(int64_t *)card_out = 0; *active_proto = 0; return -1;
}
int32_t c_scard_reconnect(void *card, uint32_t share, uint32_t proto, uint32_t disposition, uint32_t *active_proto) {
    (void)card; (void)share; (void)proto; (void)disposition; *active_proto = 0; return -1;
}
int32_t c_scard_disconnect(void *card, uint32_t disposition) { (void)card; (void)disposition; return -1; }
int32_t c_scard_release(void *ctx) { (void)ctx; return -1; }
int32_t c_scard_transmit(void *card, const uint8_t *send, uint32_t send_len, uint8_t *recv, uint32_t *recv_len) {
    (void)card; (void)send; (void)send_len; (void)recv; *recv_len = 0; return -1;
}
int32_t c_scard_reader_state(void *ctx, const char *reader, uint32_t *state_out) { (void)ctx; (void)reader; *state_out = 0; return -1; }
int32_t c_scard_reader_atr(void *ctx, const char *reader, uint8_t *atr, uint32_t *atr_len) {
    (void)ctx; (void)reader; (void)atr; *atr_len = 0; return -1;
}

#endif

// MARK: - AES block primitives

#ifdef CPCSC_OPENSSL

static int32_t evp_aes(int encrypt, const EVP_CIPHER *cipher, const uint8_t *key, const uint8_t *iv,
                       const uint8_t *in, uint32_t in_len, uint8_t *out, uint32_t *out_len) {
    EVP_CIPHER_CTX *ctx = EVP_CIPHER_CTX_new();
    if (!ctx) return -1;
    int len = 0, total = 0, ok = EVP_CipherInit_ex(ctx, cipher, NULL, key, iv, encrypt);
    ok = ok && EVP_CIPHER_CTX_set_padding(ctx, 0);
    ok = ok && EVP_CipherUpdate(ctx, out, &len, in, (int)in_len);
    total = len;
    ok = ok && EVP_CipherFinal_ex(ctx, out + total, &len);
    total += len;
    EVP_CIPHER_CTX_free(ctx);
    if (out_len) *out_len = (uint32_t)total;
    return ok ? 0 : -1;
}

int32_t c_aes256_ecb_encrypt(const uint8_t *key, uint32_t key_len, const uint8_t *in, uint8_t *out) {
    if (!key || key_len != 32 || !in || !out) return -1;
    return evp_aes(1, EVP_aes_256_ecb(), key, NULL, in, 16, out, NULL);
}

int32_t c_aes256_cbc_encrypt(const uint8_t *key, uint32_t key_len, const uint8_t *iv, const uint8_t *in, uint32_t in_len, uint8_t *out, uint32_t *out_len) {
    if (!key || key_len != 32 || !iv || (in_len && !in) || !out || !out_len ||
        in_len % 16 || in_len > INT_MAX || *out_len < in_len) return -1;
    return evp_aes(1, EVP_aes_256_cbc(), key, iv, in, in_len, out, out_len);
}

int32_t c_aes256_cbc_decrypt(const uint8_t *key, uint32_t key_len, const uint8_t *iv, const uint8_t *in, uint32_t in_len, uint8_t *out, uint32_t *out_len) {
    if (!key || key_len != 32 || !iv || (in_len && !in) || !out || !out_len ||
        in_len % 16 || in_len > INT_MAX || *out_len < in_len) return -1;
    return evp_aes(0, EVP_aes_256_cbc(), key, iv, in, in_len, out, out_len);
}



#else

int32_t c_aes256_ecb_encrypt(const uint8_t *key, uint32_t key_len, const uint8_t *in, uint8_t *out) {
    if (!key || key_len != 32 || !in || !out) return -1;
    size_t outLen = 16;
    return CCCrypt(kCCEncrypt, kCCAlgorithmAES, kCCOptionECBMode,
                    key, key_len, NULL, in, 16, out, 16, &outLen);
}

int32_t c_aes256_cbc_encrypt(const uint8_t *key, uint32_t key_len, const uint8_t *iv, const uint8_t *in, uint32_t in_len, uint8_t *out, uint32_t *out_len) {
    if (!key || key_len != 32 || !iv || (in_len && !in) || !out || !out_len ||
        in_len % 16 || in_len > INT_MAX || *out_len < in_len) return -1;
    size_t moved = 0;
    CCCryptorStatus st = CCCrypt(kCCEncrypt, kCCAlgorithmAES, 0,
                    key, key_len, iv, in, in_len, out, *out_len, &moved);
    *out_len = (uint32_t)moved;
    return st;
}

int32_t c_aes256_cbc_decrypt(const uint8_t *key, uint32_t key_len, const uint8_t *iv, const uint8_t *in, uint32_t in_len, uint8_t *out, uint32_t *out_len) {
    if (!key || key_len != 32 || !iv || (in_len && !in) || !out || !out_len ||
        in_len % 16 || in_len > INT_MAX || *out_len < in_len) return -1;
    size_t moved = 0;
    CCCryptorStatus st = CCCrypt(kCCDecrypt, kCCAlgorithmAES, 0,
                    key, key_len, iv, in, in_len, out, *out_len, &moved);
    *out_len = (uint32_t)moved;
    return st;
}



#endif

// MARK: - AES-CMAC (RFC 4493), backend-independent

int32_t c_aes256_cmac(const uint8_t *key, uint32_t key_len, const uint8_t *msg, uint32_t msg_len, uint8_t *out) {
    return c_aes256_cmac_with_block(key, key_len, msg, msg_len, out, c_aes256_ecb_encrypt);
}

int32_t c_aes256_cmac_with_block(const uint8_t *key, uint32_t key_len, const uint8_t *msg, uint32_t msg_len,
                                uint8_t *out, c_aes_block_encryptor encrypt) {
    if (!out) return -1;
    memset(out, 0, 16);
    if (!key || key_len != 32 || (msg_len && !msg) || !encrypt) return -1;
    uint8_t zero[16] = {0}, L[16], K1[16], K2[16], X[16] = {0}, Y[16], M_last[16];

    // L = AES(K, 0^128) — use separate buffers!
    int32_t status = encrypt(key, key_len, zero, L);
    if (status != 0) return status;

    // K1 = L << 1 (with R128 reduction)
    for (int i = 0; i < 15; i++) K1[i] = (L[i] << 1) | (L[i+1] >> 7);
    K1[15] = L[15] << 1;
    if (L[0] & 0x80) K1[15] ^= 0x87;

    // K2 = K1 << 1 (with R128 reduction)
    for (int i = 0; i < 15; i++) K2[i] = (K1[i] << 1) | (K1[i+1] >> 7);
    K2[15] = K1[15] << 1;
    if (K1[0] & 0x80) K2[15] ^= 0x87;

    uint32_t n = msg_len / 16 + (msg_len % 16 != 0);
    if (n == 0) n = 1;

    int last_complete = (msg_len > 0 && msg_len % 16 == 0);

    if (last_complete) {
        for (int i = 0; i < 16; i++) M_last[i] = msg[(n-1)*16 + i] ^ K1[i];
    } else {
        memset(M_last, 0, 16);
        uint32_t rem = msg_len % 16; // only 0 for an empty message (complete blocks take the branch above)
        for (uint32_t i = 0; i < rem; i++) M_last[i] = msg[(n-1)*16 + i];
        M_last[rem] = 0x80;
        for (int i = 0; i < 16; i++) M_last[i] ^= K2[i];
    }

    for (uint32_t i = 0; i < n - 1; i++) {
        for (int j = 0; j < 16; j++) Y[j] = X[j] ^ msg[i*16 + j];
        status = encrypt(key, key_len, Y, X);
        if (status != 0) return status;
    }

    for (int j = 0; j < 16; j++) Y[j] = X[j] ^ M_last[j];
    status = encrypt(key, key_len, Y, out);
    if (status != 0) memset(out, 0, 16);
    return status;
}

// MARK: - OpenSSL helpers (digests, RSA verify, TLS server)

#ifdef CPCSC_OPENSSL

int32_t c_openssl_available(void) { return 1; }

void c_sha256(const uint8_t *data, size_t len, uint8_t out[32]) {
    unsigned int n = 32;
    EVP_Digest(data, len, out, &n, EVP_sha256(), NULL);
}

void c_sha1(const uint8_t *data, size_t len, uint8_t out[20]) {
    unsigned int n = 20;
    EVP_Digest(data, len, out, &n, EVP_sha1(), NULL);
}

int32_t c_rsa_verify_digest(const uint8_t *cert_der, size_t cert_len,
                            const uint8_t *digest, size_t digest_len, const uint8_t *sig, size_t sig_len) {
    const EVP_MD *md = digest_len == 20 ? EVP_sha1() : digest_len == 32 ? EVP_sha256() : NULL;
    if (!md) return 0;
    const unsigned char *p = cert_der;
    X509 *cert = d2i_X509(NULL, &p, (long)cert_len);
    if (!cert) return 0;
    EVP_PKEY *key = X509_get_pubkey(cert);
    X509_free(cert);
    if (!key) return 0;
    EVP_PKEY_CTX *ctx = EVP_PKEY_CTX_new(key, NULL);
    int ok = ctx && EVP_PKEY_verify_init(ctx) == 1
        && EVP_PKEY_CTX_set_rsa_padding(ctx, RSA_PKCS1_PADDING) == 1
        && EVP_PKEY_CTX_set_signature_md(ctx, md) == 1
        && EVP_PKEY_verify(ctx, sig, sig_len, digest, digest_len) == 1;
    EVP_PKEY_CTX_free(ctx);
    EVP_PKEY_free(key);
    return ok ? 1 : 0;
}

void *c_tls_server_new(const uint8_t *p12_der, size_t p12_len, const char *password) {
    const unsigned char *p = p12_der;
    PKCS12 *p12 = d2i_PKCS12(NULL, &p, (long)p12_len);
    if (!p12) return NULL;
    EVP_PKEY *key = NULL;
    X509 *cert = NULL;
    STACK_OF(X509) *chain = NULL;
    int parsed = PKCS12_parse(p12, password, &key, &cert, &chain);
    if (!parsed) {
        // keytool PKCS#12 files may use RC2/3DES: OpenSSL 3 keeps those in the legacy provider
        ERR_clear_error();
        OSSL_PROVIDER_load(NULL, "legacy");
        OSSL_PROVIDER_load(NULL, "default");
        parsed = PKCS12_parse(p12, password, &key, &cert, &chain);
    }
    PKCS12_free(p12);
    if (!parsed || !key || !cert) return NULL;

    SSL_CTX *ctx = SSL_CTX_new(TLS_server_method());
    int ok = ctx && SSL_CTX_set_min_proto_version(ctx, TLS1_2_VERSION)
        && SSL_CTX_use_certificate(ctx, cert) == 1
        && SSL_CTX_use_PrivateKey(ctx, key) == 1;
    for (int i = 0; ok && chain && i < sk_X509_num(chain); i++) {
        ok = SSL_CTX_add1_chain_cert(ctx, sk_X509_value(chain, i)) == 1;
    }
    X509_free(cert);
    EVP_PKEY_free(key);
    sk_X509_pop_free(chain, X509_free);
    if (!ok) { SSL_CTX_free(ctx); return NULL; }
    return ctx;
}

void c_tls_server_free(void *server_ctx) { SSL_CTX_free((SSL_CTX *)server_ctx); }

void *c_tls_accept(void *server_ctx, int fd) {
    SSL *ssl = SSL_new((SSL_CTX *)server_ctx);
    if (!ssl) return NULL;
    SSL_set_fd(ssl, fd);
    if (SSL_accept(ssl) != 1) { SSL_free(ssl); return NULL; }
    return ssl;
}

int32_t c_tls_read(void *session, uint8_t *buf, int32_t len) { return SSL_read((SSL *)session, buf, len); }

int32_t c_tls_write(void *session, const uint8_t *buf, int32_t len) { return SSL_write((SSL *)session, buf, len); }

void c_tls_close(void *session) {
    SSL_shutdown((SSL *)session);
    SSL_free((SSL *)session);
}

#else

int32_t c_openssl_available(void) { return 0; }
void c_sha256(const uint8_t *data, size_t len, uint8_t out[32]) { (void)data; (void)len; memset(out, 0, 32); }
void c_sha1(const uint8_t *data, size_t len, uint8_t out[20]) { (void)data; (void)len; memset(out, 0, 20); }
int32_t c_rsa_verify_digest(const uint8_t *c, size_t cl, const uint8_t *d, size_t dl, const uint8_t *s, size_t sl) {
    (void)c; (void)cl; (void)d; (void)dl; (void)s; (void)sl; return 0;
}
void *c_tls_server_new(const uint8_t *p, size_t l, const char *pw) { (void)p; (void)l; (void)pw; return NULL; }
void c_tls_server_free(void *c) { (void)c; }
void *c_tls_accept(void *c, int fd) { (void)c; (void)fd; return NULL; }
int32_t c_tls_read(void *s, uint8_t *b, int32_t l) { (void)s; (void)b; (void)l; return -1; }
int32_t c_tls_write(void *s, const uint8_t *b, int32_t l) { (void)s; (void)b; (void)l; return -1; }
void c_tls_close(void *s) { (void)s; }

#endif
