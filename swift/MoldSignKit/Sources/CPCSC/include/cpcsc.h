#ifndef CPCSC_H
#define CPCSC_H

// Portable C shims for MoldSignKit. Only fixed-width types cross into Swift; the real platform
// headers (PCSC.framework / pcsc-lite, CommonCrypto / OpenSSL) are included by cpcsc.c alone,
// so DWORD/handle widths always match the platform ABI (macOS: 32-bit DWORD; Linux x64: 64-bit).

#include <stdint.h>
#include <stddef.h>

// ---- PC/SC (macOS PCSC.framework, Linux pcsc-lite; not available on iOS) ----
// ctx/card are opaque 64-bit slots owned by Swift (pass a pointer to an Int64).
extern int32_t c_scard_establish(uint32_t scope, void *ctx_out);
extern int32_t c_scard_list_readers(void *ctx, char *readers, uint32_t *len);
extern int32_t c_scard_connect(void *ctx, const char *reader, uint32_t share, uint32_t proto, void *card_out, uint32_t *active_proto);
extern int32_t c_scard_reconnect(void *card, uint32_t share, uint32_t proto, uint32_t disposition, uint32_t *active_proto);
extern int32_t c_scard_disconnect(void *card, uint32_t disposition);
extern int32_t c_scard_release(void *ctx);
extern int32_t c_scard_transmit(void *card, const uint8_t *send, uint32_t send_len, uint8_t *recv, uint32_t *recv_len);
/// Non-blocking reader state (SCardGetStatusChange, timeout 0). *state_out gets SCARD_STATE_* bits
/// (0x10 EMPTY, 0x20 PRESENT, 0x200 MUTE…). Returns the PC/SC status code.
extern int32_t c_scard_reader_state(void *ctx, const char *reader, uint32_t *state_out);
/// 1 when the PC/SC stack is usable on this platform build.
extern int32_t c_scard_available(void);

// ---- AES-256 (CommonCrypto on Apple, OpenSSL libcrypto on Linux or with MOLDSIGN_OPENSSL) ----
extern int32_t c_aes256_ecb_encrypt(const uint8_t *key, uint32_t key_len, const uint8_t *in, uint8_t *out);
extern int32_t c_aes256_cbc_encrypt(const uint8_t *key, uint32_t key_len, const uint8_t *iv, const uint8_t *in, uint32_t in_len, uint8_t *out, uint32_t *out_len);
extern int32_t c_aes256_cbc_decrypt(const uint8_t *key, uint32_t key_len, const uint8_t *iv, const uint8_t *in, uint32_t in_len, uint8_t *out, uint32_t *out_len);
// AES-256 CMAC (RFC 4493)
extern void c_aes256_cmac(const uint8_t *key, uint32_t key_len, const uint8_t *msg, uint32_t msg_len, uint8_t *out);

// ---- OpenSSL-only helpers (Linux, or macOS built with MOLDSIGN_OPENSSL for testing) ----
extern void c_sha256(const uint8_t *data, size_t len, uint8_t out[32]);
extern void c_sha1(const uint8_t *data, size_t len, uint8_t out[20]);
/// RSA PKCS#1 v1.5 over a digest (20 bytes = SHA-1, 32 = SHA-256) with the public key of an X.509 certificate (DER). 1 = valid.
extern int32_t c_rsa_verify_digest(const uint8_t *cert_der, size_t cert_len,
                                   const uint8_t *digest, size_t digest_len, const uint8_t *sig, size_t sig_len);
/// TLS server context from a PKCS#12 identity (loads OpenSSL's legacy provider if needed). NULL on failure.
extern void *c_tls_server_new(const uint8_t *p12, size_t p12_len, const char *password);
extern void c_tls_server_free(void *server_ctx);
/// Wraps an accepted socket; NULL when the handshake fails.
extern void *c_tls_accept(void *server_ctx, int fd);
extern int32_t c_tls_read(void *session, uint8_t *buf, int32_t len);
extern int32_t c_tls_write(void *session, const uint8_t *buf, int32_t len);
extern void c_tls_close(void *session);
/// 1 when the OpenSSL helpers above are compiled in.
extern int32_t c_openssl_available(void);


// MoldSign-compatible password file primitives; callers own all buffers.
int32_t c_file_password_key(const uint8_t *password, size_t password_len,
                           const uint8_t salt[16], uint8_t *key, size_t key_len);
int32_t c_file_aes_cbc(int32_t encrypt, const uint8_t *key, size_t key_len,
                     const uint8_t iv[16], const uint8_t *input, size_t input_len,
                     uint8_t *output, size_t *output_len);

int32_t c_file_rsa_wrap(const uint8_t *certificate, size_t certificate_len,
                        const uint8_t *input, size_t input_len, uint8_t *output, size_t *output_len);
int32_t c_file_local_volume(int32_t fd);

int32_t c_file_legacy_decrypt(int32_t algorithm, const uint8_t *password, size_t plen,
    const uint8_t *salt, size_t slen, uint32_t iterations, const uint8_t *input, size_t ilen, uint8_t *output, size_t *olen);

#endif // CPCSC_H
