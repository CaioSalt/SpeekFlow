# Imagem do cliente web do Stoat com branding "SpeekFlow"
# O rebrand roda em tempo de EXECUCAO (apos inject.js), pois o dist_injected
# e regenerado a cada start do container.
FROM ghcr.io/stoatchat/for-web:607a0ce

COPY SpeekFlow-wordmark.svg /tmp/SpeekFlow-wordmark.svg
COPY rebrand.sh /tmp/rebrand.sh

# mesmo CMD original, com o rebrand encaixado apos inject.js
CMD ["sh", "-c", "export PATH=/app/node_modules/.bin:$PATH && node inject.js && sh /tmp/rebrand.sh && sirv dist_injected --port 5000 --cors --single --host"]
