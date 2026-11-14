# Notas sobre a correção do LiveKit (S21 FE / proot)

## Sintoma
O processo `livekit` subia, não logava nada, não abria a porta 7880 e nunca
saía. O `start-all.sh` ficava preso esperando-o.

## Causa
No boot, o LiveKit chama `prometheus.Init(...)` incondicionalmente. Isso executa
`getTCStats()`, que envia um `RTM_GETQDISC` via netlink para o kernel e espera a
resposta numa goroutine sem timeout (`go-tc` → `lockedReceive` → `Recvmsg`).

O kernel do Android destes aparelhos **nunca responde** ao dump de qdiscs — ou
responde com mensagens que o `go-tc` ignora — e a goroutine bloqueia para sempre.
Como é antes do `bind()` e antes do primeiro log, o processo parece "morto".

Diagnóstico (executado no aparelho):
- `SIGQUIT` no processo → stack dump do Go mostrou `getTCStats` → `netlink Recvmsg`.
- `tc qdisc` devolve lista vazia; `ss` devolve "Permission denied" (netlink
  filtrado no Android).

## Correção aplicada
Patch de 20 bytes no binário `bin/livekit`, sobrescrevendo a função
`...telemetry/prometheus.getTCStats` para `return 0, 0, nil`:

```
mov x0, #0   // packets = 0
mov x1, #0   // drops   = 0
mov x2, #0   // err     = nil (itab=nil)
mov x3, #0   // err     = nil (data=nil)
ret
```

Única alteração de comportamento: contadores de pacotes/drops do nó ficam
sempre em zero (métricas Prometheus do LiveKit). Nada mais é afetado.

Endereço: `0x100aa60` (símbolo via `nm`, "not stripped"), offset no arquivo
`0xFFAA60`. Triple confirmado por `objdump -d`.

## Estado
- `bin/livekit` = versão 1.13.4 do `livekit-server`, binário arm64 estático.
- `bin/livekit.orig-backup` / `bin/livekit.patched-backup`: cópias locais.
- O código-fonte é público (Apache-2.0):
  `github.com/livekit/livekit-server` — arquivo
  `pkg/telemetry/prometheus/node_linux.go` (idêntico na tag v1.13.4 e na fork
  `stoatchat/livekit-server` v1.9.14).
