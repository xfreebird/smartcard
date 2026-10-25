import lldb, os

proc = lldb.debugger.GetSelectedTarget().GetProcess()
err = lldb.SBError()
regions = proc.GetMemoryRegions()
os.makedirs("/Users/nghimbovschi/Projects/smartcard/re/dumps", exist_ok=True)

MARKERS = [b"token_class_idacosmox", b"_detect_fs(): is a ID-A CosmoX"]

sel = []
sizes = {}
for i in range(regions.GetSize()):
    r = lldb.SBMemoryRegionInfo()
    regions.GetMemoryRegionAtIndex(i, r)
    if not r.IsReadable():
        continue
    base, end = r.GetRegionBase(), r.GetRegionEnd()
    size = end - base
    if size == 0 or size > 512 * 1024 * 1024:
        continue
    off = 0
    CH = 8 * 1024 * 1024
    found = 0
    while off < size:
        n = min(CH, size - off)
        data = proc.ReadMemory(base + off, n, err)
        if err.Success() and data:
            for m in MARKERS:
                found += data.count(m)
        off += n
    if found:
        print("region 0x%x size 0x%x has %d marker hits" % (base, size, found))
        sel.append((base, size))

print("dumping %d regions" % len(sel))
for base, size in sel:
    path = "/Users/nghimbovschi/Projects/smartcard/re/dumps/region_%x_%x.bin" % (base, size)
    with open(path, "wb") as f:
        off = 0
        CH = 8 * 1024 * 1024
        while off < size:
            n = min(CH, size - off)
            data = proc.ReadMemory(base + off, n, err)
            if not err.Success() or not data:
                break
            f.write(data)
            off += n
    print("dumped 0x%x size 0x%x" % (base, size))
print("done")
