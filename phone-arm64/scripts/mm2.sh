#!/bin/bash
# Descobre o limite de endereco do proot e testa se ulimit -v resolve o mmap do tcmalloc.
export LD_LIBRARY_PATH=""
cat > /tmp/mm2.py <<'PYEOF'
import ctypes, errno
libc = ctypes.CDLL("libc.so.6", use_errno=True)
libc.mmap.restype = ctypes.c_void_p
libc.mmap.argtypes = [ctypes.c_void_p, ctypes.c_size_t, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_long]
FAILED = ctypes.c_void_p(-1).value
def t(hint, size=1<<30):
    ctypes.set_errno(0)
    r = libc.mmap(ctypes.c_void_p(hint), size, 3, 0x02|0x20|0x100000, -1, 0)
    if r != FAILED:
        libc.munmap(ctypes.c_void_p(r), size); return True
    return False
base = libc.mmap(None, 4096, 0, 0x02|0x20, -1, 0)
libc.munmap(ctypes.c_void_p(base), 4096)
print(f"  base mmap(NULL) = {hex(base)}")
for h in [0x0, 0x40000000, 0x80000000, 0xC0000000, 0x100000000, 0x200000000, 0x400000000, 0x8000000000]:
    print(f"    mmap 1GB @ {hex(h):<14} -> {'OK' if t(h) else 'FALHOU'}")
PYEOF

echo "############ SEM limite ############"
/usr/bin/python3 /tmp/mm2.py
for lim in 4000000 8000000 16000000 32000000 64000000; do
  echo "############ ulimit -v $lim KB ############"
  bash -c "ulimit -v $lim; /usr/bin/python3 /tmp/mm2.py"
done
