#!/bin/bash
# Roda DENTRO do container proot.
cd /root/speekflow || exit 1
echo "=== versao libssl do container ==="
strings /usr/lib/aarch64-linux-gnu/libssl.so.3 2>/dev/null | grep -m1 "^OpenSSL "
echo "=== versao libssl fornecida (bin/lib) ==="
strings bin/lib/libssl.so.3 2>/dev/null | grep -m1 "^OpenSSL "
echo "=== ls bin/lib ==="
ls -la bin/lib/
echo ""
echo "=== rodar api COM LD_LIBRARY_PATH=bin/lib (erro completo) ==="
LD_LIBRARY_PATH=/root/speekflow/bin/lib ./bin/api --version 2>&1 | head -5
echo "RC=$?"
echo ""
echo "=== rodar api SEM LD_LIBRARY_PATH ==="
./bin/api --version 2>&1 | head -3
echo ""
echo "=== versao valkey/redis ==="
apt-cache policy valkey redis 2>/dev/null | grep -E '^[a-z]|Candidate'
echo "=== erlang ==="
apt-cache policy erlang 2>/dev/null | grep -E '^erlang|Candidate'
