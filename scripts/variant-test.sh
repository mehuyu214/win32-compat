#!/bin/bash
# VARIANT MATRIX — prepared 2026-11-12, DO NOT RUN while load-shedding hold is in effect.
# One variable at a time for the SIGSEGV-after-EGL-init crashes (Majikoi, RE:D Cherish).
# usage: variant-test.sh <tag> <prefix> <z-exe> ; knobs via env:
#   QEMU_BIN   (default qemu10 10.0.2; alt: $VT/qemu/usr/bin/qemu-i386-static = 8.2.2)
#   QEMU_CPU   (default max; alt: qemu32, pentium3)
#   GALLIUM_DRIVER (llvmpipe default; alt: softpipe -- kills LLVM JIT path)
#   LP_NUM_THREADS (alt: 1)
#   WINVER     (if set, winecfg winver applied to the prefix beforehand -- manual step)
set -u
. "$HOME/workspace/win32-compat/scripts/common.env"
export WINEPREFIX="$2"
cd /tmp || exit 1
LOG="$HOME/workspace/win32-compat/logs/variant-$1.log"
setsid nohup $SUP $QEMU "$WINEBIN" "$3" >> "$LOG" 2>&1 &
echo $! > "$HOME/workspace/win32-compat/logs/variant-$1.pid"
echo "variant $1 launched pgid $! qemu=$QEMU_BIN cpu=$QEMU_CPU gallium=${GALLIUM_DRIVER:-llvmpipe}"
