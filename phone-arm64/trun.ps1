#!/usr/bin/env pwsh
<#
  trun.ps1 - roda comandos dentro do Termux (celular) via ADB, sem depender de interacao manual.

  Uso:
    .\trun.ps1 -Cmd "ls -la"                 # comando inline (foreground)
    .\trun.ps1 -File .\meu-script.sh         # executa um script do PC (foreground)
    .\trun.ps1 -File .\meu-script.sh -Async  # executa em background, log em ~/trun.log
    .\trun.ps1 -Log 100                      # ultimas 100 linhas do log
    .\trun.ps1 -Stop                         # mata o processo em background
#>
param(
  [string]$Cmd,
  [string]$File,
  [int]$Log = 0,
  [switch]$Async,
  [switch]$Stop,
  [switch]$Push
)

$ErrorActionPreference = 'Stop'
$Adb      = Join-Path $PSScriptRoot '..\adb\platform-tools\adb.exe'
$THome     = '/data/data/com.termux/files/home'
$TermuxB  = '/data/data/com.termux/files/usr/bin/bash'
$TermuxTE = '/data/data/com.termux/files/usr/bin/tee'
$RemoteLog = "$THome/trun.log"
$RemotePid = "$THome/trun.pid"

# preamble de ambiente (executado DENTRO do Termux)
$EnvBlock = @'
export HOME=/data/data/com.termux/files/home
export PREFIX=/data/data/com.termux/files/usr
export PATH=$PREFIX/bin:/system/bin
export LD_LIBRARY_PATH=$PREFIX/lib
export TMPDIR=$PREFIX/tmp
export TERM=xterm-256color
export LANG=en_US.UTF-8
'@

function Send-Stdin([string]$Script) {
  $Script | & $Adb shell "run-as com.termux $TermuxB -s"
}

if ($Stop) {
  Send-Stdin "$EnvBlock`nkill `$(cat $RemotePid 2>/dev/null) 2>/dev/null; rm -f $RemotePid; echo 'parado.'"
  exit 0
}

if ($Log -gt 0) {
  Send-Stdin "$EnvBlock`ntail -n $Log $RemoteLog 2>/dev/null || echo '(sem log ainda)'"
  exit 0
}

if ($Cmd) {
  Send-Stdin "$EnvBlock`n$Cmd"
  exit 0
}

if (-not $File) { Write-Host "Use -Cmd, -File, -Log ou -Stop"; exit 1 }

$content = Get-Content -Raw -LiteralPath $File
$script  = "$EnvBlock`n$content"

if ($Push) {
  # apenas copia o script para o Termux (sem executar)
  $target = '/data/data/com.termux/files/home/' + [IO.Path]::GetFileName($File)
  $script | & $Adb shell "run-as com.termux $TermuxTE $target" | Out-Null
  Write-Host "enviado para $target"
  exit 0
}

if ($Async) {
  # 1) grava o script no celular via tee (sem redirecionamento do shell do device)
  $script | & $Adb shell "run-as com.termux $TermuxTE $THome/_trun.sh"
  # 2) lanca em background, desacoplado da sessao adb
  $launch = @"
$EnvBlock
rm -f $RemoteLog
nohup setsid $TermuxB $THome/_trun.sh > $RemoteLog 2>&1 < /dev/null &
echo `$! > $RemotePid
echo 'background iniciado, pid ' `$(cat $RemotePid)
"@
  Send-Stdin $launch
} else {
  Send-Stdin $script
}

