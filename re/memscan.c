/*
 * memscan — scan a (own-user, non-hardened) process's memory for patterns.
 * Usage: memscan <pid> <hex-pattern> [<hex-pattern> ...]
 * Prints hit addresses and context, saves contexts to memscan_hits.txt
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <mach/mach.h>
#include <mach/mach_vm.h>
#include <mach/vm_region.h>
#include <mach/vm_map.h>

static int hexval(char c) {
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    return -1;
}

static unsigned char *parse_hex(const char *s, size_t *n) {
    size_t len = strlen(s);
    if (len % 2) return NULL;
    *n = len / 2;
    unsigned char *b = malloc(*n);
    for (size_t i = 0; i < *n; i++) {
        int hi = hexval(s[2*i]), lo = hexval(s[2*i+1]);
        if (hi < 0 || lo < 0) { free(b); return NULL; }
        b[i] = (unsigned char)((hi << 4) | lo);
    }
    return b;
}

int main(int argc, char **argv) {
    if (argc < 3) { fprintf(stderr, "usage: %s <pid> <hex-pattern>...\n", argv[0]); return 1; }
    int pid = atoi(argv[1]);

    mach_port_t task;
    kern_return_t kr = task_for_pid(mach_task_self(), pid, &task);
    if (kr != KERN_SUCCESS) { fprintf(stderr, "task_for_pid failed: %s\n", mach_error_string(kr)); return 1; }

    FILE *out = fopen("/Users/nghimbovschi/Projects/smartcard/re/memscan_hits.txt", "a");

    for (int p = 2; p < argc; p++) {
        size_t pn;
        unsigned char *pat = parse_hex(argv[p], &pn);
        if (!pat) { fprintf(stderr, "bad hex: %s\n", argv[p]); continue; }
        printf("== pattern %s (%zu bytes) ==\n", argv[p], pn);
        fprintf(out, "== pattern %s ==\n", argv[p]);

        mach_vm_address_t addr = 0;
        mach_vm_size_t size = 0;
        natural_t depth = 0;
        int hits = 0;
        for (;;) {
            vm_region_submap_info_data_64_t info;
            mach_msg_type_number_t count = VM_REGION_SUBMAP_INFO_COUNT_64;
            kr = mach_vm_region_recurse(task, &addr, &size, &depth,
                                        (vm_region_recurse_info_t)&info, &count);
            if (kr != KERN_SUCCESS) break;
            if (info.is_submap) { depth++; continue; }
            if (depth > 0) { /* skip submaps */ addr += size; continue; }
            int readable = (info.protection & VM_PROT_READ);
            if (!readable || size == 0 || size > 512ULL * 1024 * 1024) { addr += size; continue; }

            /* read in chunks */
            mach_vm_size_t off = 0;
            while (off < size) {
                mach_vm_size_t chunk = size - off;
                if (chunk > 8ULL * 1024 * 1024) chunk = 8ULL * 1024 * 1024;
                mach_vm_address_t data;
                mach_msg_type_number_t data_cnt = 0;
                kr = mach_vm_read(task, addr + off, (int)chunk, &data, &data_cnt);
                if (kr == KERN_SUCCESS && data_cnt >= pn) {
                    const unsigned char *b = (const unsigned char *)(uintptr_t)data;
                    for (mach_msg_type_number_t i = 0; i + pn <= data_cnt; i++) {
                        if (memcmp(b + i, pat, pn) == 0) {
                            hits++;
                            printf("  HIT at %#llx (region %#llx+%#llx)\n",
                                   (unsigned long long)(addr + off + i),
                                   (unsigned long long)addr, (unsigned long long)off);
                            fprintf(out, "HIT %s at %llx:\n", argv[p],
                                    (unsigned long long)(addr + off + i));
                            size_t ctx = 96;
                            size_t start = (i > ctx) ? i - ctx : 0;
                            size_t end = (i + pn + ctx < data_cnt) ? i + pn + ctx : data_cnt;
                            for (size_t k = start; k < end; k++) fprintf(out, "%02X", b[k]);
                            fprintf(out, "\n\n");
                        }
                    }
                }
                if (kr == KERN_SUCCESS) mach_vm_deallocate(mach_task_self(), data, data_cnt);
                off += chunk;
            }
            addr += size;
        }
        printf("  total hits: %d\n", hits);
        free(pat);
    }
    fclose(out);
    return 0;
}
