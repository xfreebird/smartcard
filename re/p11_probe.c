/*
 * p11_probe — loads the bit4xpki PKCS#11 middleware and enumerates
 * slots/slots' tokens. No login, no signing — public data only.
 * Run with DYLD_INSERT_LIBRARIES=pcsc_trace.dylib to capture the APDU flow.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dlfcn.h>

typedef unsigned char CK_BYTE;
typedef unsigned char CK_BBOOL;
typedef unsigned long CK_ULONG;
typedef unsigned long CK_RV;
typedef void *CK_VOID_PTR;
typedef CK_BYTE *CK_BYTE_PTR;
typedef CK_ULONG *CK_ULONG_PTR;

#define CKR_OK 0UL
#define CK_TRUE 1
#define CKF_TOKEN_PRESENT 0x00000001UL
#define CKF_REMOVABLE_DEVICE 0x00000002UL
#define CKF_HW_SLOT 0x00000004UL
#define CKF_RNG 0x00000001UL
#define CKF_WRITE_PROTECTED 0x00000002UL
#define CKF_LOGIN_REQUIRED 0x00000004UL
#define CKF_USER_PIN_INITIALIZED 0x00000008UL
#define CKF_TOKEN_INITIALIZED 0x00000400UL

typedef struct {
    CK_BYTE slotDescription[64];
    CK_BYTE manufacturerID[32];
    CK_ULONG flags;
    CK_BYTE hardwareVersion[2];
    CK_BYTE firmwareVersion[2];
} CK_SLOT_INFO;

typedef struct {
    CK_BYTE label[32];
    CK_BYTE manufacturerID[32];
    CK_BYTE model[16];
    CK_BYTE serialNumber[16];
    CK_ULONG flags;
    CK_ULONG ulMaxSessionCount;
    CK_ULONG ulSessionCount;
    CK_ULONG ulMaxRwSessionCount;
    CK_ULONG ulRwSessionCount;
    CK_ULONG ulMaxPinLen;
    CK_ULONG ulMinPinLen;
    CK_ULONG ulTotalPublicMemory;
    CK_ULONG ulFreePublicMemory;
    CK_ULONG ulTotalPrivateMemory;
    CK_ULONG ulFreePrivateMemory;
    CK_BYTE hardwareVersion[2];
    CK_BYTE firmwareVersion[2];
    CK_BYTE utcTime[16];
} CK_TOKEN_INFO;

typedef struct {
    CK_BYTE major;
    CK_BYTE minor;
} CK_VERSION;

/* Cryptoki function list, exact PKCS#11 v2.x member order */
typedef struct {
    CK_VERSION version;
    CK_RV (*C_Initialize)(CK_VOID_PTR);
    CK_RV (*C_Finalize)(CK_VOID_PTR);
    CK_RV (*C_GetInfo)(CK_VOID_PTR);
    CK_RV (*C_GetFunctionList)(CK_VOID_PTR);
    CK_RV (*C_GetSlotList)(CK_BBOOL, CK_ULONG_PTR, CK_ULONG_PTR);
    CK_RV (*C_GetSlotInfo)(CK_ULONG, CK_VOID_PTR);
    CK_RV (*C_GetTokenInfo)(CK_ULONG, CK_VOID_PTR);
    CK_RV (*C_GetMechanismList)(CK_ULONG, CK_VOID_PTR, CK_ULONG_PTR);
    CK_RV (*C_GetMechanismInfo)(CK_ULONG, CK_ULONG, CK_VOID_PTR);
    CK_RV (*C_InitToken)(CK_ULONG, CK_BYTE_PTR, CK_ULONG, CK_BYTE_PTR);
    CK_RV (*C_InitPIN)(CK_VOID_PTR, CK_BYTE_PTR, CK_ULONG);
    CK_RV (*C_SetPIN)(CK_VOID_PTR, CK_BYTE_PTR, CK_ULONG, CK_BYTE_PTR, CK_ULONG);
    CK_RV (*C_OpenSession)(CK_ULONG, CK_ULONG, CK_VOID_PTR, CK_VOID_PTR, CK_VOID_PTR);
    CK_RV (*C_CloseSession)(CK_VOID_PTR);
    CK_RV (*C_CloseAllSessions)(CK_ULONG);
    CK_RV (*C_GetSessionInfo)(CK_VOID_PTR, CK_VOID_PTR);
    CK_RV (*C_GetOperationState)(CK_VOID_PTR, CK_BYTE_PTR, CK_ULONG_PTR);
    CK_RV (*C_SetOperationState)(CK_VOID_PTR, CK_BYTE_PTR, CK_ULONG, CK_VOID_PTR, CK_VOID_PTR);
    CK_RV (*C_Login)(CK_VOID_PTR, CK_ULONG, CK_BYTE_PTR, CK_ULONG);
    CK_RV (*C_Logout)(CK_VOID_PTR);
    CK_RV (*C_CreateObject)(CK_VOID_PTR, CK_VOID_PTR, CK_ULONG, CK_VOID_PTR);
    CK_RV (*C_CopyObject)(CK_VOID_PTR, CK_VOID_PTR, CK_ULONG, CK_VOID_PTR, CK_ULONG);
    CK_RV (*C_DestroyObject)(CK_VOID_PTR, CK_VOID_PTR);
    CK_RV (*C_GetObjectSize)(CK_VOID_PTR, CK_VOID_PTR, CK_ULONG_PTR);
    CK_RV (*C_GetAttributeValue)(CK_VOID_PTR, CK_VOID_PTR, CK_VOID_PTR, CK_ULONG);
    CK_RV (*C_SetAttributeValue)(CK_VOID_PTR, CK_VOID_PTR, CK_VOID_PTR, CK_ULONG);
    CK_RV (*C_FindObjectsInit)(CK_VOID_PTR, CK_VOID_PTR, CK_ULONG);
    CK_RV (*C_FindObjects)(CK_VOID_PTR, CK_VOID_PTR, CK_ULONG, CK_ULONG_PTR);
    CK_RV (*C_FindObjectsFinal)(CK_VOID_PTR);
} CK_FUNCTION_LIST_MIN;

/* minimal attribute types */
typedef struct {
    CK_ULONG type;
    void *pValue;
    CK_ULONG ulValueLen;
} CK_ATTRIBUTE;

#define CKA_CLASS 0x00000000UL
#define CKA_TOKEN 0x00000001UL
#define CKA_LABEL 0x00000003UL
#define CKA_VALUE 0x00000011UL
#define CKA_ID 0x00000102UL
#define CKO_CERTIFICATE 1UL
#define CKO_PUBLIC_KEY 2UL
#define CKO_PRIVATE_KEY 3UL
#define CKO_DATA 0UL
#define CKF_SERIAL_SESSION 2UL

static void show(const char *what, const CK_BYTE *b, int n) {
    char tmp[256];
    int i, j = 0;
    for (i = 0; i < n && j < (int)sizeof(tmp) - 1; i++)
        tmp[j++] = b[i] ? b[i] : ' ';
    while (j > 0 && tmp[j - 1] == ' ') j--;
    tmp[j] = 0;
    printf("  %s: \"%s\"\n", what, tmp);
}

int main(int argc, char **argv) {
    const char *lib = argc > 1 ? argv[1]
        : "/Applications/STISC/MoldSign/native_lib/libbit4xpki.dylib";
    void *h = dlopen(lib, RTLD_NOW);
    if (!h) {
        printf("dlopen failed: %s\n", dlerror());
        return 1;
    }
    printf("dlopen OK: %s\n", lib);

    CK_RV (*getfl)(void **) = dlsym(h, "C_GetFunctionList");
    if (!getfl) {
        printf("no C_GetFunctionList: %s\n", dlerror());
        return 2;
    }
    CK_FUNCTION_LIST_MIN *fn = NULL;
    CK_RV rv = getfl((void **)&fn);
    if (rv != CKR_OK || !fn) {
        printf("C_GetFunctionList rv=%lu\n", rv);
        return 3;
    }
    printf("PKCS#11 version %d.%d\n", fn->version.major, fn->version.minor);

    rv = fn->C_Initialize(NULL);
    printf("C_Initialize -> %lu\n", rv);
    if (rv != CKR_OK) return 4;

    CK_ULONG nslots = 0;
    rv = fn->C_GetSlotList(CK_TRUE, NULL, &nslots);
    printf("C_GetSlotList(present, NULL) -> %lu, slots=%lu\n", rv, nslots);
    if (rv != CKR_OK || nslots == 0) {
        fn->C_Finalize(NULL);
        return 5;
    }
    CK_ULONG *slots = malloc(nslots * sizeof(CK_ULONG));
    rv = fn->C_GetSlotList(CK_TRUE, slots, &nslots);
    printf("C_GetSlotList -> %lu, slots=%lu\n", rv, nslots);

    for (CK_ULONG i = 0; i < nslots; i++) {
        CK_SLOT_INFO si;
        memset(&si, 0, sizeof(si));
        rv = fn->C_GetSlotInfo(slots[i], &si);
        printf("slot %lu: C_GetSlotInfo -> %lu\n", slots[i], rv);
        if (rv == CKR_OK) {
            show("slotDescription", si.slotDescription, sizeof(si.slotDescription));
            show("manufacturerID", si.manufacturerID, sizeof(si.manufacturerID));
            printf("  flags=%#lx (present=%d removable=%d hw=%d)\n", si.flags,
                   !!(si.flags & CKF_TOKEN_PRESENT), !!(si.flags & CKF_REMOVABLE_DEVICE),
                   !!(si.flags & CKF_HW_SLOT));
        }
        CK_TOKEN_INFO ti;
        memset(&ti, 0, sizeof(ti));
        rv = fn->C_GetTokenInfo(slots[i], &ti);
        printf("slot %lu: C_GetTokenInfo -> %lu\n", slots[i], rv);
        if (rv == CKR_OK) {
            show("label", ti.label, sizeof(ti.label));
            show("manufacturerID", ti.manufacturerID, sizeof(ti.manufacturerID));
            show("model", ti.model, sizeof(ti.model));
            show("serialNumber", ti.serialNumber, sizeof(ti.serialNumber));
            printf("  flags=%#lx loginRequired=%d pinInitialized=%d tokenInitialized=%d\n",
                   ti.flags, !!(ti.flags & CKF_LOGIN_REQUIRED),
                   !!(ti.flags & CKF_USER_PIN_INITIALIZED),
                   !!(ti.flags & CKF_TOKEN_INITIALIZED));
            printf("  pinLen min=%lu max=%lu\n", ti.ulMinPinLen, ti.ulMaxPinLen);
            printf("  hw=%d.%d fw=%d.%d\n",
                   ti.hardwareVersion[0], ti.hardwareVersion[1],
                   ti.firmwareVersion[0], ti.firmwareVersion[1]);
        }
        CK_ULONG nmech = 0;
        rv = fn->C_GetMechanismList(slots[i], NULL, &nmech);
        if (rv == CKR_OK && nmech) {
            CK_ULONG *mechs = malloc(nmech * sizeof(CK_ULONG));
            rv = fn->C_GetMechanismList(slots[i], mechs, &nmech);
            printf("slot %lu: mechanisms(%lu):", slots[i], nmech);
            for (CK_ULONG m = 0; m < nmech; m++) printf(" %#lx", mechs[m]);
            printf("\n");
            free(mechs);
        }
    }

    /* enumerate objects on the first slot (no PIN: public data only) */
    CK_ULONG hSession = 0;
    CK_ULONG sessFlags = getenv("P11_RW") ? (CKF_SERIAL_SESSION | 1UL) : CKF_SERIAL_SESSION;
    rv = fn->C_OpenSession(slots[0], sessFlags, NULL, NULL, (void *)&hSession);
    printf("C_OpenSession -> %lu hSession=%lu\n", rv, hSession);
    if (rv == CKR_OK) {
        rv = fn->C_FindObjectsInit((void *)(uintptr_t)hSession, NULL, 0);
        printf("C_FindObjectsInit(all) -> %lu\n", rv);
        for (int round = 0; rv == CKR_OK && round < 64; round++) {
            CK_ULONG objh = 0, found = 0;
            rv = fn->C_FindObjects((void *)(uintptr_t)hSession, (void *)&objh, sizeof(objh), &found);
            if (rv != CKR_OK || found == 0) break;
            /* class + label + id first */
            CK_ULONG cls = 0xFFFFFFFFUL;
            CK_ATTRIBUTE q1[] = {{CKA_CLASS, &cls, sizeof(cls)}};
            fn->C_GetAttributeValue((void *)(uintptr_t)hSession, (void *)(uintptr_t)objh, q1, 1);
            CK_ATTRIBUTE q2[] = {
                {CKA_LABEL, NULL, 0},
                {CKA_ID, NULL, 0},
                {CKA_VALUE, NULL, 0},
            };
            fn->C_GetAttributeValue((void *)(uintptr_t)hSession, (void *)(uintptr_t)objh, q2, 3);
            char *label = q2[0].ulValueLen ? calloc(1, q2[0].ulValueLen + 1) : NULL;
            unsigned char *id = q2[1].ulValueLen ? calloc(1, q2[1].ulValueLen) : NULL;
            unsigned char *val = q2[2].ulValueLen ? calloc(1, q2[2].ulValueLen) : NULL;
            q2[0].pValue = label; q2[1].pValue = id; q2[2].pValue = val;
            rv = fn->C_GetAttributeValue((void *)(uintptr_t)hSession, (void *)(uintptr_t)objh, q2, 3);
            printf("obj=%#lx class=%lu label=\"%s\" idLen=%lu valLen=%lu\n",
                   (unsigned long)objh, cls, label ? label : "", q2[1].ulValueLen, q2[2].ulValueLen);
            if (q2[1].ulValueLen && id) {
                printf("  id:");
                for (CK_ULONG k = 0; k < q2[1].ulValueLen; k++) printf(" %02X", id[k]);
                printf("\n");
            }
            if (cls == CKO_CERTIFICATE && val && q2[2].ulValueLen) {
                char fname[64];
                snprintf(fname, sizeof(fname), "re/cert_obj%lx.der", (unsigned long)objh);
                FILE *out = fopen(fname, "wb");
                if (out) { fwrite(val, 1, q2[2].ulValueLen, out); fclose(out); }
                printf("  -> saved %s (%lu bytes)\n", fname, q2[2].ulValueLen);
            }
            free(label); free(id); free(val);
        }
        fn->C_FindObjectsFinal((void *)(uintptr_t)hSession);
        fn->C_CloseSession((void *)(uintptr_t)hSession);
        printf("object enumeration done\n");
    }

    fn->C_Finalize(NULL);
    printf("probe done\n");
    return 0;
}
