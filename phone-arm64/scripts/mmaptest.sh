#!/bin/bash
# Testa o comportamento de mmap dentro do container proot.
export DEBIAN_FRONTEND=noninteractive
apt-get install -y -o Acquire::Retries=3 --no-install-recommends python3-minimal >/dev/null 2>&1
cat > /tmp/mmaptest.py <<'PYEOF'
import ctypes, errno
libc = ctypes.CDLL("libc.so.6", use_errno=True)
libc.mmap.restype = ctypes.c_void_p
libc.mmap.argtypes = [ctypes.c_void_p, ctypes.c_size_t, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_long]
PROT_RW = 3; MAP_PRIVATE = 0x02; MAP_ANON = 0x20
MAP_FIXED = 0x10; MAP_FIXED_NOREPLACE = 0x100000
FAILED = ctypes.c_void_p(-1).value

def t(hint, flags, size=1<<30):
    ctypes.set_errno(0)
    r = libc.mmap(ctypes.c_void_p(hint) if hint is not None else None, size, PROT_RW, MAP_PRIVATE|MAP_ANON|flags, -1, 0)
    e = ctypes.get_errno()
    if r != FAILED:
        print(f"  hint={hint if hint is None else hex(hint)!s:<16} flags={hex(flags):<12} -> OK {hex(r)}")
        libc.munmap(ctypes.c_void_p(r), size)
    else:
        print(f"  hint={hint if hint is None else hex(hint)!s:<16} flags={hex(flags):<12} -> FALHOU errno={e} ({errno.errorcode.get(e,e)})")

print("=== MAP_FIXED_NOREPLACE (1GB alinhado, como o tcmalloc faz) ===")
for h in [0x4e66c0000000, 0x1000000000, 0x800000000, 0x100000000, 0x20000000, 0x10000000]:
    t(h, MAP_FIXED_NOREPLACE)
print("=== MAP_FIXED ===")
for h in [0x4e66c0000000, 0x1000000000, 0x800000000, 0x100000000, 0x20000000]:
    t(h, MAP_FIXED)
print("=== MAP_FIXED_NOREPLACE com tamanho pequeno (4MB) ===")
for h in [0x4e66c0000000, 0x1000000000, 0x100000000]:
    t(h, MAP_FIXED_NOREPLACE, size=4<<20)
print("=== sem hint ===")
t(None, 0)
PYEOF
python3 /tmp/mmaptest.py
