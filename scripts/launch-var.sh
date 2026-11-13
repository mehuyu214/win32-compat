#!/bin/bash
# usage: launch-var.sh <tag> <prefix> <z-exe> [extra wine args]
# Knobs via env: Q32_CPU (default max), Q32_QEMU (default static 8.2.2),
# GALLIUM_DRIVER, WINEDEBUG. Supervisor is the compat-local q32sup-var so
# CPU/qemu choices reach ALL wine processes (stock q32sup82 hardcodes
# qemu-i386-static + -cpu max into child wrappers).
set -u
. "$HOME/workspace/win32-compat/scripts/common.env"
export WINEPREFIX="$2"
export Q32_CPU="${Q32_CPU:-max}"
export Q32_QEMU="${Q32_QEMU:-$VT/qemu/usr/bin/qemu-i386-static}"
SUP="$HOME/workspace/win32-compat/tools/q32sup-var"
QEMU="$Q32_QEMU -cpu $Q32_CPU -L $VT/sysroot32/root"
cd /tmp || exit 1
LOG="$HOME/workspace/win32-compat/logs/var-$1.log"
setsid nohup $SUP $QEMU "$WINEBIN" "$3" ${@:4} >> "$LOG" 2>&1 &
echo $! > "$HOME/workspace/win32-compat/logs/var-$1.pid"
echo "var $1 launched pgid $! qemu=$Q32_QEMU cpu=$Q32_CPU gallium=${GALLIUM_DRIVER:-llvmpipe} winedebug=$WINEDEBUG"
