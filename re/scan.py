import lldb

PATTERNS = [
    ("const16", bytes.fromhex("492D28A5F7722BE4222BA37B4D53FE83")),
    ("lua_bytecode_hdr", b"\x1bLua"),
    ("idacosmox", b"idacosmox"),
    ("cosmox", b"cosmox"),
]

proc = lldb.debugger.GetSelectedTarget().GetProcess()
err = lldb.SBError()
regions = proc.GetMemoryRegions()
n = regions.GetSize()
print("regions: %d" % n)
out = open("/Users/nghimbovschi/Projects/smartcard/re/memscan_hits.txt", "a")

total_hits = {name: 0 for name, _ in PATTERNS}
CHUNK = 4 * 1024 * 1024
for i in range(n):
    r = lldb.SBMemoryRegionInfo()
    regions.GetMemoryRegionAtIndex(i, r)
    if not r.IsReadable():
        continue
    base = r.GetRegionBase()
    size = r.GetRegionEnd() - base
    if size == 0 or size > 1 * 1024 * 1024 * 1024:
        continue
    off = 0
    while off < size:
        chunk = min(CHUNK, size - off)
        data = proc.ReadMemory(base + off, chunk, err)
        if err.Success() and data:
            for name, pat in PATTERNS:
                start = 0
                while True:
                    idx = data.find(pat, start)
                    if idx < 0:
                        break
                    total_hits[name] += 1
                    addr = base + off + idx
                    print("HIT %s at 0x%x" % (name, addr))
                    cs = max(0, idx - 96)
                    ce = min(len(data), idx + len(pat) + 96)
                    out.write("HIT %s at %x:\n" % (name, addr))
                    out.write(data[cs:ce].hex())
                    out.write("\n\n")
                    out.flush()
                    start = idx + 1
        off += chunk

print("TOTALS: " + repr(total_hits))
out.close()
