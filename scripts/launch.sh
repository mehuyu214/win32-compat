#!/bin/bash
# usage: launch.sh <prefix-dir> <z-exe-path> <logfile> <pidfile> [extra wine args...]
set -u
. "$HOME/workspace/win32-compat/scripts/common.env"
export WINEPREFIX="$1"
cd /tmp || exit 1
setsid nohup $SUP $QEMU "$WINEBIN" "$2" >> "$3" 2>&1 &
echo $! > "$4"
echo "launched pgid $! prefix=$1 exe=$2"
