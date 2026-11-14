# compat line state (remaining-items shift, KK order 2026-11-14 09:06 JST)

status: COMPLETE — all three remaining items done; all compat
processes stopped, machine handed back (parent unfreezes Sanoba)
last_update: 2026-11-14 09:5x JST

KK's rules (binding, from 08:49 + 09:06): ONE game at a time
globally, never parallel; solve everything besides Sanoba.
Sanoba standing run was SIGSTOP-frozen by the parent for this
window (perf line-state: FROZEN-SANOBA window 2) and was NOT
touched by this line.

## Item 1 — Stella regression: WORKS (RESULTS.md §W)
q32sup-var + Q32_CPU=max,-avx2 + twm on :114, prefix stella-v1,
stock llvmpipe. Title at t+240 s → はじめから → story, dialog
advancing, 0 uncaught exceptions. The file-open dialog from the
interrupted 08:49 attempt did not reappear. No regression from
max,-avx2 or from the WM-always recipe.

## Item 2 — Sakura on llvmpipe + WM: WORKS (RESULTS.md §X)
Stock llvmpipe (Q32_CPU=max), prefix sakura-s1, twm from boot.
Title at t+230 s; held click on Start at the MEASURED client
geometry (28,42 → root (982,601)) → story (prologue 「La gazza
ladra」), held Return advanced text. The WM gate is
render-independent: generic recipe = WM always, both stacks.
Operator note: clicks estimated from screenshots (y=582) missed
the item by ~19 px and looked "dead" — always derive menu
coordinates from xdotool getwindowgeometry.

## Item 3 — Majikoi co-factor X: bounded matrix done (RESULTS.md §Y)
On the max,-fma base, removing BMI2 / AVX512BW / BMI1 each
still crashed with the same late-site c000001d (page offset
0x41f, esi=00000008). All three EXCLUDED as X (with FMA and
AVX512F already excluded in §§R/S). AVX2 remains necessary;
`max,-avx2` remains the recommended spec. Open lead (hypothesis
level): whether a distinct co-factor exists at all is
unresolved — Nehalem,+avx2 was never carried through the late
window under the corrected criterion; a >300 s Nehalem,+avx2
run would discriminate. NOT pursued (bounded item).

## Earlier results (previous shifts)
- Sakura no Toki — SOLVED: window manager was the missing piece
  (§V virgl, §X llvmpipe confirmation).
- RE:D Cherish! — SOLVED at max,-avx2 (§T), stopped cleanly.
- Majikoi — SOLVED at max,-avx2 (§§R/S).

## Infrastructure
- All compat game processes, twm, and helpers stopped and
  verified gone at the end of this shift. No compat virgl
  server was started this shift. Xvfb :114 left up (as before).
- Compat PA daemon: tcp 47140 (idle). Shared sysroot32 has NO
  i386 libpulse; PA runs need LD_LIBRARY_PATH → win32-perf/libs32.
- Prefix note: prefixes/sakura is an empty stub; use sakura-s1.
