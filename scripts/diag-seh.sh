#!/bin/bash
# DIAGNOSTIC ONLY — prepared 2026-11-12, DO NOT RUN while load-shedding hold is in effect.
# usage: diag-seh.sh <prefix-dir> <z-exe-path> <tag>
# Runs one boot with WINEDEBUG=+seh,+loaddll so Wine prints the faulting
# module + backtrace for the qemu "uncaught target signal 11" crashes
# (Majikoi / RE:D Cherish share the signature: DRI3 warnings x2 -> SIGSEGV).
set -u
export WINEDEBUG=+seh,+loaddll
. "$HOME/workspace/win32-compat/scripts/common.env"
export WINEPREFIX="$1"
cd /tmp || exit 1
setsid nohup $SUP $QEMU "$WINEBIN" "$2" >> "$HOME/workspace/win32-compat/logs/diag-$3.log" 2>&1 &
echo $! > "$HOME/workspace/win32-compat/logs/diag-$3.pid"
echo "diag launched pgid $! tag=$3"
