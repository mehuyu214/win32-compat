# compat line state (successor shift, KK orders 2026-11-14 08:20 + 08:49 JST)

status: COMPLETE — Sakura SOLVED; all compat processes stopped,
machine handed back (parent unfreezes Sanoba)
last_update: 2026-11-14 09:0x JST

## 🎉 SAKURA NO TOKI — SOLVED (RESULTS.md §V)
The missing environment piece was a WINDOW MANAGER. On bare Xvfb
the title ignored all input on every stack (llvmpipe §§K–P, virgl
§U). With twm running on :114 (same virgl3 run, added mid-run —
only changed variable), the title responded immediately: Start →
story, Return advances text, multiple scenes/dialogs progressed.
Fix recipe: run a lightweight WM (twm verified) on the game
display. Hypothesis: engine gates input on window activation,
which bare Xvfb never delivers.

KK's rules from 08:49 (binding): ONE game at a time globally, never
parallel. Sanoba standing run is SIGSTOP-frozen by the parent
(perf line-state: FROZEN-SANOBA, 08:50) so Sakura runs alone.
RE:D / Stella / co-factor X are PARKED.

## RE:D Cherish! — VERIFIED, then stopped cleanly (detail RESULTS.md §T)
- Under Q32_CPU=max,-avx2 (q32sup-var, prefix redcherish-r1, :114):
  title menu reached, GAME START → play-mode select → story entered,
  progressed PAST the first dialog (old signal-11 point): first line,
  scene change, character 雪光 dialog — 4+ advances, 0 uncaught
  exceptions, 8 handled c000001d (thread 0090, count stable during
  story). Verdict: SOLVED like Majikoi.
- Run was resumed from the predecessor's SIGSTOP freeze (PIDs
  9598/9600/9606/9619/9625/9643, verified by cmdline+environ),
  verified, then stopped with TERM (all PIDs confirmed gone).
  Nothing left frozen.

## Stella — PARKED before verification
- Booted once under max,-avx2 (prefix stella-v1, hardlink copy at
  games/stella) but only reached a Wine file-open dialog at 60 s;
  stopped cleanly (pgid 13386 TERM) when the 08:49 orders landed.
  No verdict recorded — regression check NOT done.

## Sakura no Toki — the mission
Established/excluded before this shift (RESULTS.md §§K–Q):
boots to full title (llvmpipe); warning→title is a timer; title
ignores ALL input (clicks/holds/keys/hover); KeyPress reaches Wine's
window (+event); engine never acquires DI keyboard/mouse; input path
= GetAsyncKeyState/GetCursorPos/message pump (imports); excluded:
CPU model, audio clock (real PA), DLL gaps, rendering, X/focus
delivery.
This shift:
- §U: virgl stack EXCLUDED too — compat-local virgl server (socket
  win32-compat/virgl.sock, GLX probe verified err=0), title reached
  in ≤150 s, input + hover still byte-identical dead.
- Remaining axes being worked now: (1) real window manager on :114
  (twm) — activation/foreground semantics on bare Xvfb are suspect:
  xdotool windowactivate fails without a WM (_NET_ACTIVE_WINDOW
  unsupported), so the window may never be "active" in the sense the
  engine gates on; (2) Wine virtual desktop (explorer /desktop);
  (3) XIM / managed-window Wine settings.
- Failed prefix note: prefixes/sakura is an empty stub (0-byte
  .reg); always use prefixes/sakura-s1.

## Infrastructure
- Compat PA daemon: tcp 47140 (idle). Shared sysroot32 has NO i386
  libpulse; PA runs need LD_LIBRARY_PATH → win32-perf/libs32.
- Xvfb :114 up. Compat virgl server: started on demand, socket
  ~/workspace/win32-compat/virgl.sock (stopped when Sakura is down).
