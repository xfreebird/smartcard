#include "cpcsc.h"
#include <stdlib.h>
#include <string.h>
#if !defined(__APPLE__) || defined(MOLDSIGN_OPENSSL)
#include <openssl/evp.h>
#define FILE_OPENSSL 1
#else
#include <CommonCrypto/CommonCrypto.h>
#endif

static void file_sha256(const uint8_t *data, size_t length, uint8_t out[32]) {
#ifdef FILE_OPENSSL
    unsigned int count = 0;
    EVP_Digest(data, length, out, &count, EVP_sha256(), NULL);
#else
    CC_SHA256(data, (CC_LONG)length, out);
#endif
}
static void file_clear(void *buffer, size_t count) {
    volatile uint8_t *p = buffer;
    while (count--) *p++ = 0;
}
/* PKCS#12 SHA-256 key derivation, diversifier 1. Password bytes are UTF-16BE,
   terminated by U+0000 (empty password has zero bytes, matching BC). */
int32_t c_file_password_key(const uint8_t *password, size_t password_len,
                          const uint8_t salt[16], uint8_t *key, size_t key_len) {
    if (password_len > 4096 || (password_len & 1) ||
        (key_len != 16 && key_len != 24 && key_len != 32)) return -1;
    size_t plen = password_len ? 64 * ((password_len + 63) / 64) : 0;
    size_t ilen = 64 + plen;
    uint8_t *input = malloc(64 + ilen);
    if (!input) return -1;
    memset(input, 1, 64);
    for (size_t i = 0; i < 64; i++) input[64+i] = salt[i % 16];
    for (size_t i = 0; i < plen; i++) input[128+i] = password[i % password_len];
    uint8_t digest[32];
    file_sha256(input, 64+ilen, digest);
    for (int i = 1; i < 65537; i++) file_sha256(digest, 32, digest);
    /* All supported keys fit in the first SHA-256 block. */
    memcpy(key, digest, key_len);
    file_clear(digest, sizeof(digest));
    file_clear(input, 64+ilen); free(input);
    return 0;
}

int32_t c_file_aes_cbc(int32_t encrypt, const uint8_t *key, size_t key_len,
                      const uint8_t iv[16], const uint8_t *input, size_t input_len,
                      uint8_t *output, size_t *output_len) {
    if (input_len > 64 * 1024 * 1024 || *output_len < input_len + 16 ||
        (key_len != 16 && key_len != 24 && key_len != 32)) return -1;
#ifdef FILE_OPENSSL
    const EVP_CIPHER *cipher = key_len == 16 ? EVP_aes_128_cbc() :
        key_len == 24 ? EVP_aes_192_cbc() : EVP_aes_256_cbc();
    EVP_CIPHER_CTX *ctx = EVP_CIPHER_CTX_new();
    if (!ctx) return -1;
    int a = 0, b = 0;
    int ok = EVP_CipherInit_ex(ctx, cipher, NULL, key, iv, encrypt) == 1 &&
        EVP_CipherUpdate(ctx, output, &a, input, (int)input_len) == 1 &&
        EVP_CipherFinal_ex(ctx, output+a, &b) == 1;
    EVP_CIPHER_CTX_free(ctx);
    if (!ok) { file_clear(output, *output_len); *output_len = 0; return -1; }
    *output_len = (size_t)(a+b); return 0;
#else
    size_t written = 0;
    CCCryptorStatus status = CCCrypt(encrypt ? kCCEncrypt : kCCDecrypt,
        kCCAlgorithmAES, kCCOptionPKCS7Padding, key, key_len, iv,
        input, input_len, output, *output_len, &written);
    if (status != kCCSuccess) { file_clear(output, *output_len); *output_len = 0; return -1; }
    *output_len = written; return 0;
#endif
}

#ifdef FILE_OPENSSL
#include <openssl/x509.h>
#include <openssl/rsa.h>
#endif
int32_t c_file_rsa_wrap(const uint8_t *certificate, size_t certificate_len,
                        const uint8_t *input, size_t input_len, uint8_t *output, size_t *output_len) {
#ifdef FILE_OPENSSL
    if (certificate_len > 65536 || input_len != 16) return 0;
    const unsigned char *cursor = certificate;
    X509 *cert = d2i_X509(NULL, &cursor, (long)certificate_len);
    if (!cert) return 0;
    EVP_PKEY *key = X509_get_pubkey(cert);
    EVP_PKEY_CTX *ctx = key ? EVP_PKEY_CTX_new(key, NULL) : NULL;
    int ok = ctx && EVP_PKEY_base_id(key) == EVP_PKEY_RSA && EVP_PKEY_bits(key) >= 2048 &&
        EVP_PKEY_bits(key) <= 8192 && EVP_PKEY_encrypt_init(ctx) > 0 &&
        EVP_PKEY_CTX_set_rsa_padding(ctx, RSA_PKCS1_PADDING) > 0 &&
        EVP_PKEY_encrypt(ctx, output, output_len, input, input_len) > 0;
    EVP_PKEY_CTX_free(ctx); EVP_PKEY_free(key); X509_free(cert);
    return ok;
#else
    return 0; // Apple uses Security.framework directly.
#endif
}

#ifdef __APPLE__
#include <sys/mount.h>
#else
#include <sys/vfs.h>
#endif
int32_t c_file_local_volume(int32_t fd) {
    struct statfs info;
    if (fstatfs(fd, &info) != 0) return 0;
#ifdef __APPLE__
    return (info.f_flags & MNT_LOCAL) != 0;
#else
    /* Known local filesystems only. Deny NFS, SMB, FUSE/provider mounts and unknown types. */
    switch ((unsigned long)info.f_type) {
        case 0xef53: case 0x9123683e: case 0x58465342: case 0x01021994:
        case 0x2fc12fc1: case 0xf2f52010: return 1;
        default: return 0;
    }
#endif
}

/* Read-only compatibility for MoldSign's legacy password CMS formats. */
#ifdef FILE_OPENSSL
#include <openssl/des.h>
#include <openssl/rc2.h>
#endif
static void file_legacy_hash(int md5, const uint8_t *data, size_t size, uint8_t *out) {
#ifdef FILE_OPENSSL
    unsigned int count=0; EVP_Digest(data,size,out,&count,md5 ? EVP_md5() : EVP_sha1(),NULL);
#else
    if(md5) CC_MD5(data,(CC_LONG)size,out); else CC_SHA1(data,(CC_LONG)size,out);
#endif
}
static int file_pkcs12_sha1(const uint8_t *password,size_t plen,const uint8_t *salt,size_t slen,
                            unsigned iterations,int diversifier,uint8_t *out,size_t olen) {
    size_t sn=slen ? 64*((slen+63)/64) : 0, pn=plen ? 64*((plen+63)/64) : 0;
    size_t size=sn+pn;
    uint8_t *buffer=malloc(64+size);if(!buffer)return -1;
    memset(buffer,diversifier,64);
    for(size_t i=0;i<sn;i++)buffer[64+i]=salt[i%slen];
    for(size_t i=0;i<pn;i++)buffer[64+sn+i]=password[i%plen];
    uint8_t digest[20],b[64];size_t offset=0;
    while(offset<olen) {
        file_legacy_hash(0,buffer,64+size,digest);
        for(unsigned i=1;i<iterations;i++)file_legacy_hash(0,digest,20,digest);
        size_t count=olen-offset<20 ? olen-offset:20;memcpy(out+offset,digest,count);offset+=count;
        if(offset<olen) {
            for(size_t i=0;i<64;i++)b[i]=digest[i%20];
            for(size_t chunk=0;chunk<size;chunk+=64) {
                unsigned carry=1;
                for(int j=63;j>=0;j--) {unsigned sum=buffer[64+chunk+j]+b[j]+carry;buffer[64+chunk+j]=(uint8_t)sum;carry=sum>>8;}
            }
        }
    }
    file_clear(buffer,64+size);free(buffer);file_clear(digest,20);file_clear(b,64);return 0;
}
int32_t c_file_legacy_decrypt(int32_t algorithm,const uint8_t *password,size_t plen,
    const uint8_t *salt,size_t slen,uint32_t iterations,const uint8_t *input,size_t ilen,uint8_t *output,size_t *olen) {
    if(algorithm<1 || algorithm>3 || plen>4096 || (plen&1) || slen<1 || slen>64 || !iterations || iterations>1000000 || !ilen || ilen%8 || ilen>64*1024*1024 || *olen<ilen)return -1;
    uint8_t key[24]={0},iv[8]={0};size_t klen=algorithm==1?24:algorithm==2?8:5;
    if(algorithm==2) {
        if(slen!=8)return -1;
        uint8_t buffer[2112],digest[20];size_t size=plen ? plen/2-1:0;
        for(size_t i=0;i<size;i++) {if(password[2*i]!=0 || password[2*i+1]>127)return -1;buffer[i]=password[2*i+1];}
        memcpy(buffer+size,salt,slen);file_legacy_hash(1,buffer,size+slen,digest);
        for(unsigned i=1;i<iterations;i++)file_legacy_hash(1,digest,16,digest);
        memcpy(key,digest,8);memcpy(iv,digest+8,8);file_clear(buffer,sizeof(buffer));file_clear(digest,sizeof(digest));
    } else {
        if(file_pkcs12_sha1(password,plen,salt,slen,iterations,1,key,klen) || file_pkcs12_sha1(password,plen,salt,slen,iterations,2,iv,8))return -1;
    }
    int success=1;
#ifdef FILE_OPENSSL
    if(algorithm==3) {
        RC2_KEY rc2;RC2_set_key(&rc2,5,key,40);RC2_cbc_encrypt(input,output,(long)ilen,&rc2,iv,RC2_DECRYPT);file_clear(&rc2,sizeof(rc2));
    } else {
        DES_key_schedule a,b,c;DES_set_key_unchecked((const_DES_cblock *)key,&a);
        if(algorithm==1) {DES_set_key_unchecked((const_DES_cblock *)(key+8),&b);DES_set_key_unchecked((const_DES_cblock *)(key+16),&c);DES_ede3_cbc_encrypt(input,output,(long)ilen,&a,&b,&c,(DES_cblock *)iv,DES_DECRYPT);}
        else DES_ncbc_encrypt(input,output,(long)ilen,&a,(DES_cblock *)iv,DES_DECRYPT);
        file_clear(&a,sizeof(a));file_clear(&b,sizeof(b));file_clear(&c,sizeof(c));
    }
#else
    size_t written=0;
    success=CCCrypt(kCCDecrypt,algorithm==1?kCCAlgorithm3DES:algorithm==2?kCCAlgorithmDES:kCCAlgorithmRC2,0,key,klen,iv,input,ilen,output,*olen,&written)==kCCSuccess && written==ilen;
#endif
    file_clear(key,sizeof(key));file_clear(iv,sizeof(iv));
    if(!success){file_clear(output,*olen);*olen=0;return -1;}
    unsigned padding=output[ilen-1];unsigned invalid=(padding<1 || padding>8);
    for(unsigned i=0;i<8;i++)if(i<padding && output[ilen-1-i]!=padding)invalid=1;
    if(!success || invalid){file_clear(output,*olen);*olen=0;return -1;}
    *olen=ilen-padding;return 0;
}
