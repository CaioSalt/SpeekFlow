#!/bin/bash
# SpeekFlow - verificar se cada servico responde
check() { (echo >/dev/tcp/127.0.0.1/$1) 2>/dev/null && echo "  OK    $2 (porta $1)" || echo "  FALHA $2 (porta $1)"; }
check 6379  "Valkey (cache/filas)"
check 5672  "RabbitMQ"
check 9000  "Silo/MinIO (arquivos)"
check 14702 "API (usa MongoDB Atlas)"
check 14703 "Eventos"
check 14704 "Autumn (upload HTTP)"
check 14705 "January (proxy)"
check 14706 "GifBox (gifs)"
check 7880  "LiveKit (voz/video)"
check 8500  "Voice-Ingress"
check 5000  "Web (deve estar desligado)"
check 8080  "Caddy LAN (HTTP)"
check 8443  "Caddy Ext (HTTPS)"
