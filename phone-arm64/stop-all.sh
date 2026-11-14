#!/bin/bash
# SpeekFlow - desligar todos os servicos
pkill -x caddy 2>/dev/null; pkill -f "sirv dist_injected" 2>/dev/null
pkill -x voice-ingress 2>/dev/null; pkill -x pushd 2>/dev/null; pkill -x crond 2>/dev/null
pkill -x gifbox 2>/dev/null; pkill -x january 2>/dev/null; pkill -x autumn 2>/dev/null
pkill -x events 2>/dev/null; pkill -x api 2>/dev/null; pkill -x livekit 2>/dev/null
pkill -x silo 2>/dev/null
valkey-cli shutdown 2>/dev/null
pkill -f beam.smp 2>/dev/null
echo "SpeekFlow desligado."
