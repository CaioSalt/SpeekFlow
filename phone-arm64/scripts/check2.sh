#!/bin/bash
# Roda DENTRO do container proot (Ubuntu 26.04).
for p in redis-server valkey-server rabbitmq-server erlang-base nodejs npm mongodb-org-server mongodb-server caddy ffmpeg gpg gnupg python3 file xz-utils; do
  v=$(apt-cache policy "$p" 2>/dev/null | sed -n 's/^  Candidate: //p')
  echo "$p => ${v:-NAO DISPONIVEL}"
done
echo "--- sources ---"
cat /etc/apt/sources.list.d/ubuntu.sources | head -20
echo "--- glibc real ---"
/lib/x86_64-linux-gnu/libc.so.6 2>/dev/null | head -1
ls /lib/aarch64-linux-gnu/libc.so.6 2>/dev/null && /lib/aarch64-linux-gnu/libc.so.6 | head -1
