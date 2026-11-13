# Diagnostic plan (prepared during load-shedding hold, 2026-11-12)

## Shared crash signature (Majikoi まじこい.exe AND RE:D Cherish!)
Both die identically: wine processes exec, libEGL prints the DRI3 warning
pair, then `qemu: uncaught target signal 11 (Segmentation fault)`.
Sanoba/Stella (Kirikiri) survive the same stack. Evidence:
- win32-compat/logs/majikoi1.log (Majikoi direct boot of the real exe)
- sanoba-play/logs/redcherish3.log + redcherish-vd.log (same signature,
  plain and virtual-desktop launches)

## Import-table facts (objdump, host-side)
- まじこい.exe: d3d9.dll + **d3dx9_35.dll** + DINPUT8 + DSOUND + MSVFW32.
  (Its bundled DirectX/ folder is exactly the AUG2007 d3dx9_35 redist.)
- red_cherish_eb_try_plus.exe: NO d3d9 import; Pal.dll uses gdiplus +
  DSOUND + vorbisfile; graphics DLLs FX.dll/RESOURCE.dll present.
  => RED may crash in a different component than Majikoi despite the
  same outer signature; the +seh run will tell (faulting module name).
- Sakura exe: d3d9.dll + DINPUT(8-less) + DSOUND + WS2_32; boots, engine
  creates savedata, window renders nothing (solid white) — separate track.

## Hypotheses for the segfault (ranked)
1. llvmpipe LLVM JIT emits code qemu TCG faults on when a game compiles
   real shaders (Kirikiri's fixed-function path never triggers it).
   Test: GALLIUM_DRIVER=softpipe (env-only, no sysroot change).
2. -cpu max exposes a feature (CPUID leaf) the games/engines mis-handle.
   Test: QEMU_CPU=pentium3, then qemu32.
3. qemu 10.0.2 TCG regression. Test: QEMU_BIN=qemu 8.2.2 static.
4. Wine builtin d3dx9_35 stub crash (Majikoi only). Test: +seh backtrace
   names the module; if d3dx9_35, propose native d3dx9_35 from the game's
   own bundled cab as a *prefix-side* DLL override (still not a game edit).

## Run order once released (bursty, one boot at a time, 1280x720 :114)
1. diag-seh.sh Majikoi  -> faulting module/backtrace (logs/diag-majikoi-seh.log)
2. variant-test.sh Majikoi GALLIUM_DRIVER=softpipe
3. variant-test.sh Majikoi QEMU_CPU=pentium3
4. variant-test.sh Majikoi QEMU_BIN=qemu8
5. Same ladder for RE:D Cherish (dialog -> OK click via xdotool after boot)
6. Sakura: WINEDEBUG=+loaddll,+d3d boot; eglprobe inside its prefix;
   check d3dcompiler/d3dx9/xinput/mfplat load failures.
7. REGRESSION: re-run Sanoba + Stella title boots after any proposed
   shared change (env-only changes first; sysroot additions are PROPOSALS
   for the parent, never applied by this line).
