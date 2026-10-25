/*
 * sm_probe — probe the Moldovan eID card's IAS/ECC secure-messaging
 * establishment (EXTERNAL AUTHENTICATE) to determine whether the card
 * accepts host-chosen ECDH key material (=> fully replicable on iOS),
 * or requires key material embedded in bit4xpki.
 *
 * No PIN is used. No card state is modified (SM sessions are ephemeral;
 * the card is reset between variants).
 *
 * Per variant, replicate the middleware's exact sequence:
 *   SELECT IAS AID -> SELECT MF -> SELECT EF D003/READ -> MSE SET(C1A4)
 *   -> GET CHALLENGE -> EXTERNAL AUTHENTICATE(96B) -> observe SW/response
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <PCSC/PCSC.h>
#include <Security/Security.h>
#include <CoreFoundation/CoreFoundation.h>

static SCARDCONTEXT ctx;
static SCARDHANDLE card;
static DWORD proto;
static FILE *xf; /* exchange log */

static const unsigned char IAS_AID[] = {
    0xA0, 0x00, 0x00, 0x00, 0x77, 0x03, 0x0C, 0x60, 0x00, 0x00, 0x00, 0xFE, 0x00, 0x00, 0x05, 0x00};
static const unsigned char CONST16[] = {
    0x49, 0x2D, 0x28, 0xA5, 0xF7, 0x72, 0x2B, 0xE4, 0x22, 0x2B, 0xA3, 0x7B, 0x4D, 0x53, 0xFE, 0x83};
/* captured EXTERNAL AUTH tail from apdu_capture.log line 213 */
static const unsigned char REPLAY_TAIL[] = {
    0x81, 0xA3, 0xB1, 0x20, 0x1D, 0x51, 0x7D, 0x1B, 0x2E, 0xDD, 0x34, 0x36, 0xBC, 0x6A, 0x4E, 0x6B,
    0x32, 0x91, 0x92, 0x48, 0xB8, 0xC9, 0x49, 0x06, 0xA3, 0x1F, 0xC3, 0x32, 0x74, 0x4C, 0x9D, 0xA5,
    0xA7, 0x32, 0x84, 0x49, 0xFE, 0xA0, 0x5D, 0x01, 0x72, 0x9B, 0x55, 0xE0, 0x02, 0xF0, 0xA2, 0x01,
    0x5E, 0xB0, 0xC8, 0xDE, 0xE0, 0x4E, 0x35, 0x2B, 0x2C, 0xD3, 0xF7, 0x24, 0x5B, 0x6C, 0xB0, 0xC0,
    0x76, 0x2E, 0xF4, 0x80, 0xE4, 0xBB, 0xC4, 0x18, 0x14, 0x5A, 0xA3, 0x89, 0x12, 0xA6, 0x39, 0xF7, 0x60};

static void print_hex(const char *label, const unsigned char *b, size_t n) {
    printf("  %s: ", label);
    for (size_t i = 0; i < n; i++) printf("%02X", b[i]);
    printf("\n");
}

static void log_line(const char *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    vfprintf(xf, fmt, ap);
    va_end(ap);
    fputc('\n', xf);
    fflush(xf);
}

/* transmit with T=0 61xx/6Cxx chaining; returns total data length, SW in sw[2] */
static DWORD tx_apdu(const unsigned char *snd, DWORD sn, unsigned char *rsp, DWORD cap, unsigned char sw[2]) {
    SCARD_IO_REQUEST sio, rio;
    sio.dwProtocol = proto; sio.cbPciLength = sizeof(SCARD_IO_REQUEST);
    rio.dwProtocol = proto; rio.cbPciLength = sizeof(SCARD_IO_REQUEST);
    DWORD n = cap;
    LONG r = SCardTransmit(card, &sio, snd, sn, &rio, rsp, &n);
    if (r != SCARD_S_SUCCESS) { printf("  !! SCardTransmit error %08lX\n", (unsigned long)r); sw[0]=0xFF; sw[1]=0xFF; return 0; }
    for (int guard = 0; guard < 8 && n >= 2; guard++) {
        if (rsp[n-2] == 0x61) {
            unsigned char gr[270], grq[5] = {0x00, 0xC0, 0x00, 0x00, rsp[n-1]};
            DWORD gn = sizeof(gr);
            if (SCardTransmit(card, &sio, grq, 5, &rio, gr, &gn) != SCARD_S_SUCCESS) break;
            n -= 2;
            memcpy(rsp + n, gr, gn);
            n += gn;
        } else if (rsp[n-2] == 0x6C) {
            unsigned char again[16]; DWORD an;
            memcpy(again, snd, sn); again[4] = rsp[n-1]; an = cap;
            if (SCardTransmit(card, &sio, again, sn, &rio, rsp, &an) != SCARD_S_SUCCESS) break;
            n = an;
        } else break;
    }
    if (n >= 2) { sw[0] = rsp[n-2]; sw[1] = rsp[n-1]; n -= 2; }
    return n;
}

static int sw_ok(const unsigned char sw[2]) { return sw[0] == 0x90 && sw[1] == 0x00; }

static int connect_card(void) {
    LONG r = SCardEstablishContext(SCARD_SCOPE_USER, NULL, NULL, &ctx);
    if (r != SCARD_S_SUCCESS) return -1;
    DWORD n = 0;
    r = SCardListReaders(ctx, NULL, NULL, &n);
    if (r != SCARD_S_SUCCESS || n == 0) return -1;
    char *names = malloc(n);
    SCardListReaders(ctx, NULL, names, &n);
    char *reader = strdup(names);
    free(names);
    r = SCardConnect(ctx, reader, SCARD_SHARE_SHARED, SCARD_PROTOCOL_T0 | SCARD_PROTOCOL_T1, &card, &proto);
    free(reader);
    printf("connected, proto=%lu\n", (unsigned long)proto);
    return (r == SCARD_S_SUCCESS) ? 0 : -1;
}

static void reset_card(void) {
    SCardDisconnect(card, SCARD_RESET_CARD);
    connect_card();
}

/* full pre-handshake sequence; returns 0 ok, fills challenge[16] */
static int prep(unsigned char challenge[16]) {
    unsigned char rsp[2048], sw[2], snd[64];
    DWORD n;

    snd[0] = 0x00; snd[1] = 0xA4; snd[2] = 0x04; snd[3] = 0x00; snd[4] = (unsigned char)sizeof(IAS_AID);
    memcpy(snd + 5, IAS_AID, sizeof(IAS_AID));
    snd[5 + sizeof(IAS_AID)] = 0x00; /* Le */
    n = tx_apdu(snd, 6 + sizeof(IAS_AID), rsp, sizeof(rsp), sw);
    if (!sw_ok(sw)) { printf("  SELECT AID failed SW=%02X%02X\n", sw[0], sw[1]); return -1; }

    n = tx_apdu((unsigned char[]){0x00,0xA4,0x00,0x0C,0x02,0x3F,0x00,0x00}, 8, rsp, sizeof(rsp), sw);
    if (!sw_ok(sw)) { printf("  SELECT MF failed SW=%02X%02X\n", sw[0], sw[1]); return -1; }

    n = tx_apdu((unsigned char[]){0x00,0xA4,0x02,0x04,0x02,0xD0,0x03,0x00}, 8, rsp, sizeof(rsp), sw);
    if (!sw_ok(sw)) { printf("  SELECT D003 failed SW=%02X%02X\n", sw[0], sw[1]); return -1; }
    n = tx_apdu((unsigned char[]){0x00,0xB0,0x00,0x00,0x00}, 5, rsp, sizeof(rsp), sw);
    if (!sw_ok(sw)) { printf("  READ D003 failed SW=%02X%02X\n", sw[0], sw[1]); return -1; }

    n = tx_apdu((unsigned char[]){0x00,0x22,0xC1,0xA4,0x09,0x80,0x04,0xFF,0x40,0x10,0x8C,0x83,0x01,0x04}, 14, rsp, sizeof(rsp), sw);
    if (!sw_ok(sw)) { printf("  MSE SET failed SW=%02X%02X\n", sw[0], sw[1]); return -1; }

    n = tx_apdu((unsigned char[]){0x00,0x84,0x00,0x00,0x10}, 5, rsp, sizeof(rsp), sw);
    if (!sw_ok(sw) || n != 16) { printf("  GET CHALLENGE failed SW=%02X%02X n=%lu\n", sw[0], sw[1], (unsigned long)n); return -1; }
    memcpy(challenge, rsp, 16);
    return 0;
}

/* returns 0 if external auth accepted (9000) */
static int ext_auth(const unsigned char payload[96]) {
    unsigned char snd[5 + 96], rsp[2048], sw[2];
    snd[0]=0x00; snd[1]=0x82; snd[2]=0x00; snd[3]=0x00; snd[4]=0x60;
    memcpy(snd + 5, payload, 96);
    DWORD n = tx_apdu(snd, sizeof(snd), rsp, sizeof(rsp), sw);
    print_hex("SW ", sw, 2);
    if (sw[0] == 0x90 && sw[1] == 0x00 && n > 0) print_hex("RESP", rsp, n);
    else if (n > 0) print_hex("ERR", rsp, n);
    return sw_ok(sw) ? 0 : -1;
}

static void put_hex(FILE *f, const unsigned char *b, size_t n) {
    for (size_t i = 0; i < n; i++) fprintf(f, "%02X", b[i]);
}

/* generate fresh EC keypair; pubraw = X||Y (2*bits/8); returns SecKeyRef private */
static SecKeyRef gen_ec(int bits, unsigned char *pubraw, CFDataRef *priv_ext) {
    CFMutableDictionaryRef p = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(p, kSecAttrKeyType, kSecAttrKeyTypeECSECPrimeRandom);
    CFNumberRef bn = CFNumberCreate(NULL, kCFNumberIntType, &bits);
    CFDictionarySetValue(p, kSecAttrKeySizeInBits, bn);
    SecKeyRef priv = SecKeyCreateRandomKey(p, NULL);
    CFRelease(bn); CFRelease(p);
    if (!priv) { printf("  !! EC keygen failed\n"); return NULL; }
    SecKeyRef pub = SecKeyCopyPublicKey(priv);
    CFErrorRef e = NULL;
    CFDataRef d = SecKeyCopyExternalRepresentation(pub, &e);
    if (!d) { printf("  !! pub external repr failed\n"); CFRelease(priv); return NULL; }
    /* public external repr = 04||X||Y */
    memcpy(pubraw, CFDataGetBytePtr(d) + 1, (size_t)CFDataGetLength(d) - 1);
    CFRelease(d); CFRelease(pub);
    e = NULL;
    *priv_ext = SecKeyCopyExternalRepresentation(priv, &e);
    return priv;
}

int main(void) {
    unsigned char challenge[16], payload[96];
    xf = fopen("/Users/nghimbovschi/Projects/smartcard/re/sm_exchanges.log", "a");
    if (!xf) xf = stderr;

    if (connect_card() != 0) { printf("no reader/card\n"); return 1; }

    struct variant { const char *name; int kind; } vs[] = {
        {"replay_captured", 0},
        {"zeros96", 1},
        {"const16_zeros80", 2},
        {"const16_random80", 3},
        {"random96", 4},
        {"p384_pub_raw96", 5},
        {"const16_p256pub65_z15", 6},
        {"const16_p256pub64_z16", 7},
    };
    int nvars = (int)(sizeof(vs) / sizeof(vs[0]));

    for (int i = 0; i < nvars; i++) {
        printf("=== variant %s ===\n", vs[i].name);
        if (prep(challenge) != 0) { printf("  prep failed, resetting\n"); reset_card(); continue; }
        print_hex("challenge", challenge, 16);

        memset(payload, 0, sizeof(payload));
        SecKeyRef priv = NULL; CFDataRef priv_ext = NULL;
        unsigned char pubraw[128]; size_t publen = 0;

        switch (vs[i].kind) {
        case 0:
            memcpy(payload, CONST16, 16);
            memcpy(payload + 16, REPLAY_TAIL, 80);
            break;
        case 1: break; /* zeros */
        case 2:
            memcpy(payload, CONST16, 16);
            break;
        case 3:
            memcpy(payload, CONST16, 16);
            arc4random_buf(payload + 16, 80);
            break;
        case 4:
            arc4random_buf(payload, 96);
            break;
        case 5:
            priv = gen_ec(384, pubraw, &priv_ext);
            if (!priv) { printf("  keygen failed\n"); continue; }
            memcpy(payload, pubraw, 96); /* X||Y = 96 */
            publen = 96;
            break;
        case 6: {
            unsigned char p256[65];
            priv = gen_ec(256, p256, &priv_ext); /* p256 = X||Y (64) */
            if (!priv) { printf("  keygen failed\n"); continue; }
            memcpy(payload, CONST16, 16);
            payload[16] = 0x04;
            memcpy(payload + 17, p256, 64);
            /* remaining 15 bytes stay zero */
            publen = 64;
            break;
        }
        case 7: {
            unsigned char p256[65];
            priv = gen_ec(256, p256, &priv_ext);
            if (!priv) { printf("  keygen failed\n"); continue; }
            memcpy(payload, CONST16, 16);
            memcpy(payload + 16, p256, 64);
            /* remaining 16 bytes stay zero */
            publen = 64;
            break;
        }
        }

        int rc = ext_auth(payload);

        /* log the exchange */
        fprintf(xf, "EX variant=%s rc=%d challenge=", vs[i].name, rc);
        put_hex(xf, challenge, 16);
        fprintf(xf, " payload=");
        put_hex(xf, payload, 96);
        fprintf(xf, "\n");
        if (priv_ext) {
            fprintf(xf, "KEY variant=%s pub=", vs[i].name);
            put_hex(xf, pubraw, publen ? publen : 96);
            fprintf(xf, " priv=");
            put_hex(xf, CFDataGetBytePtr(priv_ext), (size_t)CFDataGetLength(priv_ext));
            fprintf(xf, "\n");
        }
        fflush(xf);

        if (rc == 0) {
            printf("  *** ACCEPTED (9000) ***\n");
            /* probe: does the card now enforce SM for a plain command? */
            unsigned char rsp[2048], sw[2];
            tx_apdu((unsigned char[]){0x00,0x84,0x00,0x00,0x10}, 5, rsp, sizeof(rsp), sw);
            printf("  plain GET CHALLENGE after accept: SW=%02X%02X\n", sw[0], sw[1]);
        }
        if (priv) { CFRelease(priv); if (priv_ext) CFRelease(priv_ext); }

        reset_card(); /* clean slate for the next variant */
        printf("\n");
    }

    SCardDisconnect(card, SCARD_LEAVE_CARD);
    SCardReleaseContext(ctx);
    fclose(xf);
    printf("probe done\n");
    return 0;
}
