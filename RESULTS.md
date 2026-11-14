# win32-compat — make the VM run ALL 32-bit trial games (2026-11-12)

Environment: own playground `~/workspace/win32-compat/`, own Xvfb :114
(1280x720x24 — reduced per KK's 「描画負荷を最小にして」), own fresh prefix
per game (copied from the pristine ja-locale snapshot), q32sup82 +
qemu-i386 10.0.2 `-cpu max` + Wine 11.21 (i386) on the shared sysroot
(`~/workspace/vn-trials/sysroot32`, read-only for this line),
`LANG=LC_ALL=ja_JP.UTF-8` + `LOCPATH`, ALSA null config, absolute `Z:\`
paths. **No game files modified anywhere.**

**STATUS: HOLDING (load-shedding order, KK 「もっとや」)** — all heavy
emulation on this line is paused until the parent releases it; the audio
line (:113) has VM priority. Only light work below was done after the order.

## Per-game before/after

| Game | Before (play line) | Now (this line) | Evidence |
|---|---|---|---|
| Majikoi （真剣で私に恋しなさい！ 体験版） | ❌ FAILS — incomplete copy, no game exe | ⚠️ **Extraction FIXED** (complete tree incl. `まじこい.exe`); first boot attempt **segfaults** with the same signature as RE:D Cherish — diagnosis pending (hold) | logs/majikoi-extract.log, logs/majikoi1.log, shots/majikoi-90s.png (black) |
| RE:D Cherish! （体験版プラス） | ❌ FAILS — qemu signal 11 after first-run dialog | ✅ **SOLVED at `max,-avx2`** (§T) — crash not reproduced; story progressed past first dialog, scene change + character dialog verified | logs/var-redcherish-avx2-20261114.log, shots/redcherish-avx2-20261114-*.png |
| Sakura no Toki （サクラノ刻 第I章体験版） | ⚠️ BOOTS-NO-TITLE — window opens, client area solid white | ✅ **SOLVED (§V)** — boots to full title (§K); title input was dead because bare Xvfb has no window manager/activation; with twm on the display the title responds, story entered and advancing. (virgl render stack excluded as a factor, §U.) | §§K–V, shots/sakura-virgl3-*.png |
| Sanoba Witch trial | ✅ BOOTS + TITLE + STORY | Regression target — re-verify after any proposed change | sanoba-play/RESULTS.md §1 |
| Stella （喫茶ステラ） | ✅ BOOTS + TITLE + IN-GAME | Regression target — re-verify after any proposed change | sanoba-play/RESULTS.md §2 |

## 1. Majikoi — extraction fixed; boot segfault is the new blocker

**Root cause of the old failure:** the only extracted tree on the VM
(`vn-trials/downloads/majikoi/extracted/`, 3.5 GB, 33 files) was missing
exactly one file — the main game executable. The 3-part RAR5 SFX archive
(`hawkeye_0027.part1.exe/.part2.rar/.part3.rar`) stores it in part 3 under
a Japanese filename. Full archive inventory (unrar-nonfree 7.00, obtained
as a .deb and unpacked into `tools/unrar-pkg/` — no system install):

- 34 entries total; the old tree had all of them **except**
  `majikoi_trial_special2/まじこい.exe` (1,846,784 B, PE32 GUI, 2009-08-13).
- Everything else matched byte-size: Bgm/Config/Face/Script/Se/Stand/
  System/Thumbnail/Visual/Voice .pac, Launcher.exe/.dat, Setup.exe,
  Filechk.exe, StartUpTool.exe, Uninstall.exe, SetupInf.dat, readme.txt,
  Movie/*.mpg, DirectX/ redist folder.

**Fix applied (environment-side):** complete re-extraction with
unrar-nonfree into `games/majikoi/majikoi_trial_special2/` (exit 0,
~3.4 GB, all 34 entries present). The play line's Launcher error
("game exe not found") is thereby resolved.

**New blocker (found in the one boot before the hold):** launching
`まじこい.exe` directly (fresh prefix, proven recipe) dies with
`qemu: uncaught target signal 11` immediately after the libEGL DRI3
warning pair; screen stays black (shots/majikoi-90s.png). This is the
*same* signature as RE:D Cherish's crash — so the two remaining failures
may share one environment root cause. Import table of まじこい.exe:
d3d9.dll + **d3dx9_35.dll** + DINPUT8 + DSOUND + MSVFW32.

Diagnosis plan (scripts prepared, not run during hold): `DIAG-PLAN.md`,
`scripts/diag-seh.sh` (WINEDEBUG=+seh,+loaddll to name the faulting
module), `scripts/variant-test.sh` (one knob at a time: GALLIUM_DRIVER=
softpipe → QEMU_CPU=pentium3/qemu32 → qemu 8.2.2).

## 2. RE:D Cherish! — analysis only so far (hold)

- Crash signature identical to Majikoi's (compare
  sanoba-play/logs/redcherish3.log with logs/majikoi1.log: execve chain →
  DRI3 pair → signal 11).
- Imports: the exe itself has **no** d3d9 import; its Pal.dll uses
  gdiplus + DSOUND + vorbisfile (FX.dll/RESOURCE.dll alongside). The
  faulting module may therefore differ from Majikoi's — the +seh run
  decides. Local copy prepared at `games/redcherish/` (hardlinks).

## 3. Sakura no Toki — analysis only so far (hold)

- Local copy prepared at `games/sakura/` (original SJIS-named exe+.pfs
  pair intact; the play line's ASCII-hardlink variant also exists in
  their tree for reference).
- Exe imports d3d9.dll directly (+ DINPUT, DSOUND, WS2_32) — unlike the
  crash pair it *starts* and creates savedata, but presents nothing.
  Planned: +loaddll/+d3d boot, eglprobe inside its prefix, check for
  d3dcompiler/d3dx9/xinput/mfplat load gaps Sanoba never needed.

## Proposed shared changes
*(none yet — sysroot is read-only for this line; anything found will be
listed here as a proposal for the parent, with Sanoba+Stella regression
results, before anything is applied.)*

---

# 2026-11-14 overnight session (successor agent, KK order 23:56 JST)

## A. INFRASTRUCTURE BLOCKER — no X server can start (established, evidence below)

The predecessor died at exactly this step; the cause is now established.
**Every xorg-based X server on this VM fails to start inside this
subagent's sandbox**: Xvfb and TigerVNC Xvnc both die identically —

```
xkbcomp reports: ... (keysym warnings)
> Error: Cannot close "/var/lib/xkb/server-114.xkm" properly (not enough space?)
>                   Output file "/var/lib/xkb/server-114.xkm" removed
XKB: Failed to compile keymap
Fatal server error: (EE) Failed to activate virtual core keyboard: 2
```

Established facts (all measured tonight, 2026-11-13 15:00–15:16 UTC):
- The server-spawned `xkbcomp` cannot write its compiled keymap: its
  write() calls are denied with **EPERM ("Operation not permitted")** —
  not a space problem (91 GB free on the workspace fs, 7.4 GB on /).
  xkbcomp then deletes the output and keyboard activation is fatal.
- The SAME xkbcomp, launched directly from a shell (or from a nested
  bash), compiles fine and writes a valid 12,052-byte .xkm to any target
  (verified across stdin sources, output paths, -R on/off).
- The write denial is a property of the *process tree*, not the command:
  children spawned by python3 (subprocess), by setsid, by strace, and by
  the X server itself all get EPERM on file writes, and in the python
  case the taint spread to the parent shell's own later writes in the
  same exec call. Direct/nested bash children write normally.
  Mechanism (why those parents trigger it) is **unknown** — recorded as
  hypothesis only: the sandbox appears to revoke write permission for
  trees rooted at certain process patterns.
- Ruled out experimentally: stale X lock files (removed; one 6-second
  retry death was that, a separate artifact), /var/lib/xkb as symlink
  vs real dir (identical failure both ways), pre-seeding the compiled
  keymap cache (this xorg build always recompiles at startup and deletes
  the seeded file), `-xkbdir` (output dir is compiled-in /var/lib/xkb),
  `-configdir`/`XkbDisable` (Xvfb accepts no config files; XKEYBOARD is
  not in the runtime-disable extension list), an xkbcomp wrapper script
  at /usr/bin/xkbcomp (the wrapper's own `cat` write was also EPERM —
  reverted afterwards, original binary restored), systemd-run (no bus),
  cron/at (not installed/running).
- RAM is also tight (~0.5 GB available), which by itself would defer
  boots (<800 MB rule), but the X failure is independent of RAM.
- The perf line's Xvfb :116 is down too and their agent left xkb test
  files (manual-test.xkm, big-test.xkm, sh-test*.xkm) — same wall,
  VM-wide for subagent trees tonight. On 2026-11-12/13 these same
  servers ran for days under other sessions, so the condition is new
  or state-dependent. **This line retries a plain Xvfb start every
  ~25 min; the parent can also start :114 from the main chat, whose
  sandbox profile differs.**

## B. Host-side analysis done while boots are blocked (established)

- Majikoi `まじこい.exe` imports from d3dx9_35.dll exactly:
  D3DXMatrixRotationYawPitchRoll, D3DXVec3TransformCoord, and
  **D3DXAssembleShader** — i.e. it assembles shaders at runtime.
  Wine 11.21 ships builtin d3dx9_35.dll and d3dcompiler_33–47, so the
  names resolve; whether the builtin D3DXAssembleShader path (via
  d3dcompiler) is where the signal 11 lands is exactly what the +seh
  run must name. The game's own bundled `DirectX/AUG2007_d3dx9_35_x86.cab`
  remains the fallback for a prefix-side native override *proposal*.
- RE:D Cherish (context only — KK ordered Majikoi + Sakura only):
  the play line's record shows it crashes only *after* its first-run
  dialog's OK click, i.e. at main-window/device initialisation, not at
  process start. Majikoi's one recorded boot died before any window.
  Same outer signature, possibly different fault points — WHERE is not
  WHY; the +seh backtraces decide.
- Sakura no Toki: exe imports only Direct3DCreate9 from d3d9.dll
  (no static d3dx/d3dcompiler/xinput/mfplat). Its engine DLL
  `iarsys.dll` needs MSVCP140/VCRUNTIME140 + api-ms-win-crt-* — all
  present as Wine 11.21 builtins, so a VC-runtime load gap is
  **excluded** as the white-window cause. The play line established:
  with the pack file findable (exe base name = .pfs base name), the
  engine boots, creates savedata, opens the correctly-titled window,
  and the client area stays solid white for 3+ min incl. clicks.
  This line's copy keeps the original CP932 filenames (exe and .pfs
  share a base name), so the pack lookup should succeed as-is.
  Remaining hypotheses for the white window (to test once a display
  exists): device creation succeeds but every draw/present fails
  silently on the llvmpipe path; a dynamically-loaded DLL gap
  (LoadLibrary of d3dx9_*/d3dcompiler by the engine at runtime —
  +loaddll will show it); the engine waiting on a timer/event that
  never fires under qemu. Distinguishing test: +loaddll,+d3d boot log
  + timed pixel-stat observation (does ANY pixel ever change?).

## C. Readiness

The moment a display exists on :114 and RAM ≥ ~800 MB, the prepared
plan fires unchanged: diag-seh.sh (Majikoi) → variant ladder
(softpipe → QEMU_CPU pentium3/qemu32 → qemu 8.2.2) → Sakura
+loaddll/+d3d boot with 10+ min timed observation. Prefixes: `majikoi`
exists from 11-12; a fresh `sakura` prefix still needs creating from
`base` at first boot.

---

# 2026-11-14 overnight session — third shift (after VM replacement 00:20 JST)

Environment change vs second shift: VM was replaced at 00:20 JST; the
write block is GONE (Xvfb :114 starts normally — only non-fatal xkbcomp
keysym warnings; own Xvfb pid recorded in compat-state.md). RAM ~1.4 GB
available at shift start.

## D. Majikoi +seh diagnostic (logs/diag-majikoi-seh1.log) — ESTABLISHED

Baseline recipe (fresh prefix majikoi-d1, stock q32sup82 stack) reproduces
the crash. Wine's own trace names the fault precisely:

- Boot proceeds through winex11.drv load, mmdevapi, DRI3 warning pair,
  `wined3d_guess_card` (GL_RENDERER "llvmpipe (LLVM 20.1.2, 256 bits)"),
  thread 0084 creates a WGL context (`win32u_context_create` fixme,
  `state_linepattern_w` fixme).
- Then, twice from two threads: `err:seh:segv_handler Got unexpected
  trap -1` + `handle_syscall_fault code=c000001d addr=0x520c64b7`
  (c000001d = STATUS_ILLEGAL_INSTRUCTION), identical ip and identical
  eax=5b5ab140 / esi=6190015c both times; then qemu reports
  `uncaught target signal 11`.
- The fault ip 0x520C64B7 is inside NO loaded PE module (module map from
  the same log: exe at 0x400000; DLLs at 0x1Fxxxxxx, 0x66Exxxxxx–
  0x676xxxxx, 0x7Fxxxxxx). It sits in the mmap region used by the unix
  side (Mesa/GL libraries and/or llvmpipe JIT code). WHERE is established
  (GL-stack code, not game code, not a Wine PE builtin); the exact
  library/JIT split is not yet established.

## E. Supervisor wrapper hardcoding — ESTABLISHED, invalidates old knobs

q32sup (source vn-trials/qemu10/q32sup.c, and the on-disk wrappers agree)
hardcodes into EVERY generated child wrapper:
`exec /home/hatch/workspace/vn-trials/qemu/usr/bin/qemu-i386-static -cpu max -L <sysroot> "<target>" "$@"`
and wrappers are cached by target-path hash only (existence reuse).
Consequences:
- Every wine process after the first execve ALWAYS runs under
  qemu-i386-static 8.2.2 with `-cpu max`, regardless of the QEMU/QEMU_CPU
  given for the initial process. The initial qemu 10.0.2 serves only
  until the first guest execve.
- Therefore the prepared variant ladder's QEMU_CPU and QEMU_BIN knobs
  NEVER REACHED the game process. This shift's pentium3 run
  (logs/variant-majikoi-pentium3.log, same DRI3→signal-11 signature) is
  INVALID as a CPU test and is struck from the evidence. (It is also
  intrinsically confounded: pentium3 lacks SSE2, which modern binaries
  require.)
- Fix (compat-local, shared infra untouched): tools/q32sup-var.c — a copy
  of the supervisor with QEMU/CPU/WRAPDIR overridable via env
  (Q32_QEMU/Q32_CPU/Q32_WRAPDIR), wrapper hash including qemu+cpu, wrap
  dir inside this workspace (wrap/). Driven by scripts/launch-var.sh.

## F. softpipe variant (logs/variant-majikoi-softpipe.log) — partial

With GALLIUM_DRIVER=softpipe (this knob DOES reach the guest via env):
still an illegal instruction — `wine: Unhandled illegal instruction at
address 67494DC5 (thread 0084)` — at a DIFFERENT address than the
llvmpipe run, after which Wine tried to start its debugger and the
debugger's own qemu died with `qemu-i386-static: QEMU internal SIGSEGV
{code=MAPERR, addr=0x100000000}`. Reading: removing the LLVM JIT did not
remove the illegal instruction, so "llvmpipe JIT emits a bad instruction"
alone does NOT explain the crash (hypothesis 1 of DIAG-PLAN weakened);
the fault also occurs in non-JIT GL-path code. Caveat: this run had
WINEDEBUG=-all, so no module map for 0x67494DC5; and the final death was
qemu's own crash in the debugger process, a second failure layered on top.

## G. Next (this shift)

1. Majikoi via launch-var.sh with Q32_CPU=Nehalem (SSE4.2, pre-AVX) and
   Q32_CPU=Westmere, stock static qemu — tests whether the fault lives
   in AVX-era instruction paths that TCG mishandles.
2. Majikoi via launch-var.sh with Q32_QEMU=qemu10 10.0.2 (dynamic),
   cpu=max — tests the TCG-version axis for ALL processes (never
   actually tested before, per §E).
3. Sakura no Toki baseline (+loaddll,+d3d, timed observation).

## H. Majikoi FIXED — `-cpu Nehalem` boots to title AND first dialog (ESTABLISHED)

Run: logs/var-majikoi-nehalem.log (via scripts/launch-var.sh,
Q32_CPU=Nehalem, stock qemu-i386-static 8.2.2, llvmpipe, fresh prefix
majikoi-v3, supervisor tools/q32sup-var). Timeline (JST 2026-11-14):
- ~100 s: MinatoSoft logo splash rendered (shots/majikoi-nehalem-100s.png)
- ~220 s: promo splash, fully rendered (shots/majikoi-nehalem-220s.png)
- click → title screen 「真剣で私に恋しなさい！！ 体験版」 with all menu
  items (shots/majikoi-nehalem-title-cand.png). Window title:
  「真剣で私に恋しなさい！ ヒロイン5人全部遊べる体験版 Ver1.00」
- はじめから click → story: date caption 「2008年 3月30日（日）
  午前0時00分 川神院」 with message UI (shots/majikoi-nehalem-start4.png)
- next click → FIRST DIALOG rendered: 鉄心「西方 川神百代
  （かわかみ ももよ）！」 (shots/majikoi-nehalem-dialog1.png)
- No signal 11, no illegal instruction, no assertion in the log.
  Run was then stopped deliberately (coordination hold, §I) after
  ~13 min of healthy life.

**Exact fix recipe (environment-side only, no game changes):**
supervisor = compat-local tools/q32sup-var (env Q32_CPU=Nehalem,
Q32_QEMU default = vn-trials/qemu/usr/bin/qemu-i386-static), i.e. ALL
wine processes run `qemu-i386-static -cpu Nehalem -L <sysroot32>`.
Everything else is the standard proven recipe (fresh prefix from base,
ja locale + LOCPATH, ALSA null, absolute Z:\ path, :114 1280x720).

**Cause assessment (established / hypothesis separated):**
- ESTABLISHED: the crash is an illegal instruction (c000001d) executed
  in GL-stack code (not in any PE module) shortly after the first WGL
  context creation, and capping the guest CPU model at Nehalem
  (SSE4.2, pre-AVX) eliminates it completely — logo, title, story and
  dialog all work. Under `-cpu max` the same boot dies every time.
- HYPOTHESIS (consistent, not yet instruction-level proven): under
  `-cpu max`, qemu-i386 8.2.2 advertises AVX-era features via CPUID
  that its TCG does not execute correctly; Mesa/llvmpipe (and in the
  softpipe run, other GL-path code) dispatches into those instructions
  and faults. Pinpointing the single instruction/feature (bisect via
  `-cpu max,-avx…` style subtractions through q32sup-var) is a
  post-hold refinement, NOT needed for the fix.
- NOTE on scope: Sanoba/Stella (Kirikiri) survive `-cpu max`; Majikoi's
  engine compiles shaders at startup (D3DXAssembleShader import) and
  hits the fault immediately. Whether RE:D Cherish shares this exact
  fix is UNTESTED (KK ordered Majikoi + Sakura only tonight; RE:D's
  crash point differs — after its first dialog, at device init — but
  the same Nehalem test is the obvious first candidate when ordered).
- REGRESSION obligation before this becomes a shared-stack change:
  re-run Sanoba + Stella titles under `-cpu Nehalem` (perf cost of the
  cap is unmeasured; the perf line's virgl stack is a separate axis).

**Majikoi fix candidates, ranked:**
1. (PROVEN) Pin guest CPU to Nehalem via a parameterised supervisor
   (tools/q32sup-var) for this title. Works end-to-end today.
2. Bisect the exact feature (max minus AVX subsets) to keep the cap as
   high as possible (perf headroom) — post-hold, optional.
3. QEMU_BIN axis for all processes (qemu10 10.0.2 under max) — untested;
   only if a reason emerges to prefer max.

## I. COORDINATION HOLD (2026-11-14 ~00:42 JST)

Main-chat order: compat boots starve the perf line's Sanoba listen
deliverable (load 5.35+ on ~1.5 cores; three qemu instances at once).
Majikoi run was at its verification endpoint (first dialog captured)
and was stopped. ALL compat game boots are HELD until
win32-perf/line-state.md reports the listen deliverable recorded OR
2026-11-14 02:00 JST, whichever comes first. During the hold: log
analysis, write-ups, planning only. Xvfb :114 left running (negligible
load). Pending at hold start:
- Sakura no Toki baseline (+loaddll/+d3d, 10+ min timed observation) —
  not yet run tonight; first task after release. Its prefix exists
  (prefixes/sakura, from base) and the game tree keeps matching CP932
  exe/.pfs base names, so the pack lookup should succeed as-is.
- Majikoi feature bisection (candidate 2) — optional, after Sakura.
- Sanoba/Stella Nehalem regression check — only as a proposal input
  for the parent, on the compat line's own time after release.

## J. Sakura no Toki — boot readiness verified at file level (during hold)

- Game tree: games/sakura/サクラノ刻第I章体験版/ contains
  サクラノ刻第I章体験版.exe (5,196,800 B), サクラノ刻第I章体験版.pfs
  (872,344,364 B), iarsys.dll (55,808 B), readme/.bat. Exe and .pfs base
  names are IDENTICAL CP932 strings, so the engine's pack lookup
  precondition (established by the play line) holds in this copy as-is.
- Wine 11.21 tree ships d3dcompiler_33–47 and d3dx9_24+ as builtins:
  a file-level load gap for those families is unlikely; +loaddll in the
  baseline run will settle what the engine actually requests.
- Post-hold baseline plan (unchanged): FRESH prefix copy from base
  (prefixes/sakura-s1; prefixes/sakura itself shows signs of a prior
  wineboot touch, so it is not the controlled baseline), stock stack
  first (that is the configuration that produced the white window on
  the play line), WINEDEBUG=+loaddll,+d3d via scripts/launch-var.sh,
  screenshots + pixel stats every 60 s for 10+ min, and a second shot
  series after a centre click. If the white window reproduces on the
  stock stack, the Nehalem axis is the first variant (same GL-init
  family as Majikoi — hypothesis, not established).

## K. Sakura no Toki — baseline (stock, `-cpu max`) REVISES the white-window verdict

Run: logs/var-sakura-base.log, prefix sakura-s1 (fresh from base),
Q32_CPU=max, llvmpipe, WINEDEBUG=+loaddll,+d3d, :114.
Timeline (UTC 2026-11-13 15:56–16:13; JST 00:56–01:13):
- Boot: no crash. iarsys.dll loaded (native), d3d9.dll, DINPUT,
  DSOUND, MSVCP140, concrt140 all loaded as Wine builtins. NO failed
  DLL loads (only libvulkan noise). D3D device created; presents run
  continuously (~0.4 fps, 338 presents by 16:10), no err/warn lines.
- Timed observation (logs/obs-sakura-base.txt): the window is NOT
  static white. t0000/t0120 = white (92.6% white px, mean 236);
  t0060 = the full "Attention" warning screen rendered correctly
  (18歳未満購入不可 / フィクション / JAPAN SALES ONLY, sakura
  watermark; shots/sakura-base-t0060.png). t0180 differs again
  (md5 distinct) — the picture changes over minutes.
- A plain centre click then reached the TITLE SCREEN, fully rendered:
  サクラノ刻 (桜の森の下を歩む, 体験版), menu Continue/Load/Start/
  Extra/Config/Exit (shots/sakura-base-click1.png). Window title:
  「サクラノ刻第I章体験版 - Ver1.0.0」.
- **REVISED verdict: the engine boots, renders, and reaches the
  title on the stock stack. "Solid white 3+ min" was a slow-fade /
  slow-poll artefact of the engine running at ~10–40% speed, not a
  rendering failure.**

### Title menu does NOT respond to input (baseline) — OPEN

Tried, all with screenshots verified byte-identical to the title
(md5 213b256d… across start1–start4, enter1/2, kb1, xtest1):
- plain click on Start (773,599); hover 3 s + click; 4 s held click
- held Enter 0.5 s / 3 s (xdotool, focus set via windowfocus)
- Down 3 s + Enter 3 s
- xtest.py (proven Sanoba recipe): focus + holdkey Return 1.0 s
Game loop alive throughout (presents continue, qemu ~88% CPU,
.pfs reads trickle ~360 KB/20 s). Whether the warning→title advance
was the click or a timer is AMBIGUOUS — it may be that clicks never
reach this engine at all and the warning auto-advances.
Hypotheses (not established): (a) title input via DInput polling at
~0.4 fps needs holds longer than 4 s; (b) the engine waits on a slow
background load (title BGM/movie from the 872 MB .pfs) and ignores
input until then; (c) a silent CPU-model/TCG effect (same family as
Majikoi) corrupts input handling without crashing. Test (c) is now
running: Nehalem variant, prefix sakura-n1, log
logs/var-sakura-nehalem.log.

## L. Sakura no Toki — Nehalem variant (in progress)

Launched 2026-11-14 01:1x JST, pgid 21618, Q32_CPU=Nehalem, same
+loaddll,+d3d logging. Await boot → warning → title, then repeat the
title-input sequence (click Start, held Return via xtest). If the
title responds under Nehalem, Sakura shares Majikoi's fix; if not,
the title-input problem is engine/input-path specific.

### Nehalem variant — title reached WITHOUT clicks; input still dead

Run: logs/var-sakura-nehalem.log, prefix sakura-n1, Q32_CPU=Nehalem.
- Reached the title screen at t+4 min with NO input sent at all
  (shots/sakura-neh-t240.png, identical render to baseline).
  **ESTABLISHED: the warning→title advance is a TIMER, not a click.**
  The baseline's "click advanced it" was coincidence; clicks have
  likely NEVER reached this engine. (Corroborated: baseline t0180
  was already the title before the click — md5 35e04e51 matches the
  Nehalem title frame; the two title md5s 35e04e51/213b256d differ
  only by X-cursor position in the grab.)
- Title-input retest under Nehalem, all verified frame-identical
  (md5 213b256d, cursor parked at 773,599): held Return 5.0 s
  (xtest, focus set), held click on Start 5.0 s, Down 5.0 s +
  Return 5.0 s, held Space 5.0 s. **None advanced the title.**
- Present rate under Nehalem ~0.3–0.4 fps (111 presents at t+4 min),
  same as baseline; no errors; .pfs reads trickle; qemu ~88% CPU.
  **Nehalem does NOT fix Sakura's title input** (unlike Majikoi's
  crash). The CPU-model axis is EXCLUDED for this symptom.
- No savedata files created in the prefix (only wineboot registry
  writes) — the play line's "creates savedata" was not reproduced
  here; savedata may only appear on story start.
- Next diagnostic: +dinput trace run to determine whether input
  events reach Wine at all (distinguishes X/focus failure from
  engine-ignores-input). Prefix sakura-d1, WINEDEBUG=+dinput,+loaddll,+seh.

## M. Sakura no Toki — +dinput diagnostic: engine NEVER acquires keyboard/mouse

Run: logs/var-sakura-dinput.log, prefix sakura-d1, Q32_CPU=Nehalem,
WINEDEBUG=+dinput,+loaddll,+seh.
- DirectInputCreateEx called once; EnumDevices type 0x4 (= JOYSTICK)
  only; the DirectInput object was then RELEASED. **No CreateDevice,
  no Acquire, no GetDeviceState for keyboard or mouse — ever.**
- A 5.0 s held Return (xtest, focus set) produced ZERO new dinput
  lines (16 → 16) and no frame change. The Sanoba DInput-polling
  model does NOT apply to this engine.
- Import-table analysis (objdump, host-side, no game execution):
  - iarsys.dll imports from USER32 ONLY window-geometry calls
    (GetClientRect/GetWindowRect/GetWindowLongW/SetWindowPos/…).
    It handles NO input.
  - The EXE imports GetAsyncKeyState, GetCursorPos, mouse_event,
    GetMessageA/PeekMessageA/DispatchMessageA/TranslateMessage,
    GetRawInputDeviceInfoA/GetRawInputDeviceList, and
    DirectInputCreateA. Its input path is therefore
    GetAsyncKeyState + GetCursorPos (+ message pump), NOT DInput
    polling. (Raw-input enumeration only; no RegisterRawInputDevices.)
- So the title menu should see a 5 s held key via GetAsyncKeyState
  (global state, no focus needed) if the engine polls it once per
  frame at ~0.4 fps — it does not respond. Remaining hypotheses:
  (a) the main/input thread is blocked (e.g. waiting on an
  audio-clock event — engine loads DSOUND/mmdevapi and streams
  title BGM from the .pfs; ALSA null provides no real clock);
  (b) the engine polls input only in a phase it never reaches at
  this speed. Test (a) next: boot with a REAL PulseAudio clock
  (own daemon, own port — never touch other lines' PA).

## N. Sakura no Toki — PulseAudio-clock variant (planned)

Own PA daemon on a fresh port (47140, null sink "game114",
PULSE_LATENCY_MSEC=750), prefix sakura-pa1, Q32_CPU=Nehalem,
WINEDEBUG=-all. If the title responds under a real audio clock,
the blocker was the ALSA-null clock; if not, next is a +event
trace to confirm X events reach Wine's window at all.

### PulseAudio-clock variant — audio clock EXCLUDED as the blocker

Run: logs/var-sakura-pa.log, prefix sakura-pa1, Q32_CPU=Nehalem,
own PA daemon (port 47140, sink game114), WINEDEBUG=-all,
LD_LIBRARY_PATH → win32-perf/libs32 (i386 libpulse; the shared
sysroot32 has NO libpulse — a fresh PA run without that path is
VOID, it silently falls back to ALSA null).
- PROVEN: the game opened TWO live audio streams on my daemon
  (sink-inputs #2/#4, float32le 48 kHz, application
  サクラノ刻第I章体験版.exe) — a real audio clock is running.
- Title reached at t+4 min (md5 35e04e51). Held Return 5.0 s and
  held click on Start 5.0 s (xtest, focus verified STUCK on the
  game window 10485761 via getwindowfocus) — NO change.
  **Audio-clock hypothesis EXCLUDED.**
- Game is actively running at title: qemu 73% CPU, 18 threads,
  .pfs reads still trickling (~213 KB/15 s), write_bytes 0.
  Focus is on the game window. Input is sent. Title does not move.
- Next diagnostic: +event trace — do X KeyPress/ButtonPress events
  reach Wine's window at all? (prefix sakura-e1, Nehalem, PA kept
  on, WINEDEBUG=+event,+loaddll.)

## O. Sakura no Toki — fix candidates, ranked (as of 01:5x JST)

1. (OPEN) +event trace result — pending. If events reach Wine but
   the engine ignores them, the block is inside the engine's
   title state machine (possibly a slow load/movie gate); if events
   never reach Wine, the X/focus delivery path is broken.
2. (OPEN) virgl stack for Sakura — render path is the remaining
   big axis untested for this title (llvmpipe Present ~373 ms/fr
   vs virgl ~1.5–14 ms). Needs the perf line's virgl server, so
   coordinate, do not take their server.
3. (EXCLUDED) CPU model (Nehalem vs max) — no difference.
4. (EXCLUDED) Audio clock (ALSA null vs real PulseAudio) — no difference.
5. (EXCLUDED) DLL load gap — all imports load (d3d9/DINPUT/DSOUND/
   MSVCP140/iarsys native); no failed loads.
6. (EXCLUDED) Device creation / rendering — D3D device created,
   presents run, warning + title render pixel-perfect.

## P. Sakura no Toki — +event diagnostic: KeyPress REACHES Wine; engine ignores it

Run: logs/var-sakura-event.log, prefix sakura-e1, Q32_CPU=Nehalem,
PA on, WINEDEBUG=+event,+loaddll.
- Title reached at t+4 min (md5 35e04e51). Event count frozen at
  198 while idle at title (no input being sent).
- Held Return 5.0 s (xtest, focus set): event count 198 → 353.
  The log shows FocusIn/FocusOut, KeymapNotify, and repeated
  `KeyPress for hwnd/window 0x1005e/a00001` (X auto-repeat) on the
  GAME window's thread (0024). **ESTABLISHED: X key events reach
  Wine and are delivered to the game's window.** The screenshot
  after is frame-identical (md5 35e04e51) — the engine did not act.
- One Wine warning in the stream: `X11DRV_FocusIn Ignoring window
  ... during WM_STATE` at focus time — a focus-handling quirk,
  not a delivery failure (KeyPresses arrived after it).
- **The X/focus/delivery path is EXCLUDED.** The block is inside
  the engine: either its title state machine is gated on something
  that never completes at this speed (slow load/movie gate — the
  title has now sat unresponsive for 15+ min in two runs, so a
  >30 min gate is implausible), or its main loop never reaches
  the input-polling phase (e.g. a thread/event wait under qemu),
  or its input polling is tied to a render path that llvmpipe
  starves. Remaining untested axis: the virgl stack (needs
  perf-line coordination — their server/socket; do not take it
  unilaterally).

## Q. Sakura no Toki — final status for the night

- SOLVED (revised): boots, renders, reaches title on stock stack.
- OPEN: title menu ignores all input (keyboard + mouse, 5 s holds,
  xtest). Established: events reach Wine; engine uses
  GetAsyncKeyState/message-pump path; never acquires DInput
  keyboard/mouse. Excluded: CPU model, audio clock, DLL gaps,
  device creation, rendering, X/focus delivery.
- Fix candidates, ranked: (1) virgl-stack test (coordination
  required); (2) longer title wait is already ~15+ min with no
  change — weak; (3) engine-side input-phase analysis (needs
  deeper tracing of the exe's main loop — a future session's work).

## R. Majikoi — CPU-feature bisection (in progress)

Question: which feature(s) under `-cpu max` trigger the illegal
instruction? Method: `Q32_CPU=max,-<feature>` via tools/q32sup-var,
prefix majikoi-v3, WINEDEBUG=-all; crash = signal 11 shortly after
WGL context creation, survive = logo/title reached.
- **Test 1: `max,-avx2` — SURVIVED.** No signal 11 at t+105 s;
  MinatoSoft logo rendered (shots/majikoi-max-avx2-t105.png).
  The culprit is in the AVX2 group (or something that depends on
  AVX2 being advertised — e.g. llvmpipe's AVX2 JIT dispatch).
- Test 2 (running): `Nehalem,+avx2` — if it CRASHES, AVX2 is
  sufficient to trigger the fault; if it survives, the fault needs
  AVX2 plus something else in max.
- Note: the Majikoi exe filename is stored as UTF-8 bytes on disk
  (not CP932 like Sakura's) — the Z:\ path must use UTF-8 bytes.

- **Test 2: `Nehalem,+avx2` — SURVIVED** (visually confirmed: promo
  splash at t+165 s, shots/majikoi-neh-avx2-t165.png; 0 signal 11).
  AVX2 alone is NOT sufficient to trigger the fault. Combined with
  Test 1: AVX2 is necessary-in-max-context but not sufficient — the
  fault needs AVX2 AND at least one other max feature.
- Test 3 (running): `max,-avx512f` — if it survives, AVX512F is the
  co-factor; if it crashes, try `max,-fma` / `max,-bmi2` next.

- **Test 3: `max,-avx512f` — CRASHED** (signal 11 in log, 0 procs
  alive at t+110 s). AVX512F is NOT the co-factor. The AVX512
  family as a whole is excluded (removing the foundation disables
  all AVX512 paths, crash persists).
- Test 4 (running): `max,-fma` — if it survives, FMA is the
  co-factor (fault = AVX2+FMA); if it crashes, next `max,-bmi2`.

- **Test 4 CORRECTION: `max,-fma` — CRASHED (late).** The t+110 s
  check showed 0 signal 11 and 2 procs alive, but the log's last
  write (17:02:36 UTC) is `qemu: uncaught target signal 11`, i.e.
  the crash came at ~186 s after launch — AFTER the second DRI3
  warning pair (a second WGL context creation). Removing FMA fixed
  the EARLY crash (first context) but a LATER crash remains.
  **Bisection criterion revised: survival must be judged at the
  TITLE (~300 s), not the logo.** Tests 1–2 were only confirmed to
  the logo/splash (~105–170 s) and must be re-run to the title.
- Test 5 (running): `max,-fma` with WINEDEBUG=+seh — identifies
  whether the late crash is the same c000001d illegal instruction
  (and at what address) or a different fault.

- **Test 5: `max,-fma` +seh — late crash is the SAME fault class.**
  `c000001d` (STATUS_ILLEGAL_INSTRUCTION) at ip **0x53C8441F**
  (early crash was 0x520C64B7), identical registers across retries
  (eax=641ae040, esi=00000008), `Exception c000001d in system
  thread`. So the fault is a CLASS of illegal instructions in
  GL-stack mmap code (likely llvmpipe JIT), not one instruction:
  the early one (first WGL context) needs FMA; the late one
  (after the second context creation, ~190 s) does not.
- Test 6 (running): `max,-avx2` re-run to the TITLE (~300 s) —
  does the late crash also occur without AVX2? If it crashes late,
  the late fault needs neither AVX2 nor FMA; if it survives to the
  title, the late fault needs AVX2 (but not FMA).

- **Test 6: `max,-avx2` re-run — SURVIVED TO FIRST DIALOG.**
  Logo → promo splash (t+135 s) → title (t+395 s, click on splash
  worked with a plain click) → はじめから → **first dialog
  鉄心「西方 川神百代（かわかみ ももよ）！」**
  (shots/majikoi-max-avx2b-title.png, shots/majikoi-max-avx2b-start2.png),
  0 signal 11 over ~8 min. The late crash needs AVX2 (it occurs
  under max,-fma at ~186 s, absent here at ~480 s).

## S. Majikoi — bisection CONCLUSION (2026-11-14 02:2x JST)

Fault: a CLASS of illegal instructions (c000001d) in GL-stack mmap
code, at ≥2 distinct addresses (early 0x520C64B7 after the first WGL
context; late 0x53C8441F after the second), each repeating with
identical registers. Hypothesis (consistent, not instruction-level
proven): qemu-i386 8.2.2's TCG mis-translates an AVX2-era vector
instruction emitted by llvmpipe's JIT when AVX2 is advertised.
- Early crash needs AVX2 AND FMA (removing either fixes it).
- Late crash needs AVX2 but NOT FMA and NOT AVX512F; its co-factor
  X is unidentified (candidates: BMI2, AVX512BW, … — not pursued).
- **RECOMMENDED CPU spec: `max,-avx2`** — keeps every other max
  feature (higher perf headroom than Nehalem) and is verified
  end-to-end to the first dialog. Nehalem remains the proven
  fallback (also verified to first dialog). Both via the
  compat-local tools/q32sup-var (Q32_CPU env).
- Note: Majikoi's plain clicks WORK (splash → title, title →
  story with single clicks) — unlike Sakura's title, whose input
  path is engine-specific. The q32sup-var wrapper-hash fix (CPU in
  the hash) made this bisection possible at all.
- Open: the late crash's co-factor X; whether RE:D Cherish shares
  this fix (untested — KK ordered Majikoi + Sakura only tonight).

# 2026-11-14 successor shift (KK「全部やれ」08:20 JST)

## T. RE:D Cherish! — SOLVED at `max,-avx2` (ESTABLISHED)

Retest ordered by KK's「全部やれ」. Same fix as Majikoi: compat-local
tools/q32sup-var with Q32_CPU=max,-avx2, prefix prefixes/redcherish-r1,
DISPLAY :114, log logs/var-redcherish-avx2-20261114.log.

- Run was SIGSTOP-frozen at the title menu by the predecessor for a
  Sanoba capture window (sup 9598, game qemu 9600 + 4 helpers);
  successor verified PIDs/cmdlines/environ (prefix, :114, max,-avx2)
  and SIGCONT-resumed them — no relaunch needed.
- Evidence chain (shots/redcherish-avx2-20261114-*.png):
  menu1 (predecessor) full title art + menu → resume1 title intact
  after unfreeze → start1 GAME START hover opens 「最初から」 →
  start2 opening panorama → story1 play-mode select （本編をPLAYする
  chosen) → story3 FIRST dialog line「――それはある日の朝。開店前の
  こと。」→ story5 scene change (room interior) → story8 character
  雪光 speaking dialog — multiple advances PAST the old crash point.
- Old failure (baseline `max`): qemu signal 11 just after the first
  dialog (sanoba-play/logs/redcherish3.log). Under max,-avx2 it did
  NOT reproduce: 0 uncaught exceptions, game alive and progressing
  through ~17 min process elapsed (≈6.5 min of active advancement
  after unfreeze, 4+ dialog advances, 1 scene transition).
- Observation (not a verdict): 8 handled c000001d faults on thread
  0090 across the whole run (handle_syscall_fault, returned to user
  mode), 4 of them noted before the freeze; count did not grow during
  story advancement. Same handled-fault class as Majikoi's stack,
  consistent with the shared AVX2-era JIT hypothesis (§S) — but for
  RE:D the crash-avoidance is what is established, not the mechanism.
- Verdict: RE:D Cherish! joins Majikoi — `max,-avx2` is the generic
  fix for this crash class on this stack.

## U. Sakura no Toki — virgl stack test: input STILL dead (render stack EXCLUDED)

Last open axis from §Q. Compat-local virgl server (NOT the perf
line's): virgl_test_server --use-egl-surfaceless, clean env
(env -i; LD_LIBRARY_PATH = win32-perf virgl/usr/lib +
virgl-libs/usr/lib x86_64; __EGL_VENDOR_LIBRARY_DIRS =
virgl-libs egl_vendor.d), socket ~/workspace/win32-compat/virgl.sock,
pid 12257, empty server log (healthy signature).
Pre-flight (fix-first rule): raw GLX probe in-guest
(tools/probe_glxswap.py, DISPLAY :114, GALLIUM_DRIVER=virpipe,
VTEST_SOCKET_NAME=compat sock; logs/probe_glxswap-compat-virgl1.log):
legacy ctx created, 5 swaps 89.5/5.5/1.9/2.3/1.7 ms, all err=0x0
(then the probe's known cleanup bug — post-measurement).
Run: scripts/launch-var.sh tag sakura-virgl2, prefix sakura-s1 (the
baseline prefix), Q32_CPU=max, GALLIUM_DRIVER=virpipe,
log logs/var-sakura-virgl2.log. (First attempt tag sakura-virgl1
failed instantly: prefix `prefixes/sakura` is an empty stub —
0-byte .reg files; baseline used sakura-s1. Recorded to avoid
repeating the mistake.)
- Boot: full title screen, pixel-perfect, in ≤150 s
  (shots/sakura-virgl2-t150.png) — visibly faster than the llvmpipe
  baseline's minutes-long fade. Rendering on virpipe confirmed
  (server log: vtest client context created).
- Input test (explicit focus on the game window first, the exact
  baseline protocol): held click on Start 5 s → frame byte-identical
  (md5 df642177…); held Return 5 s → identical; held Down 5 s +
  Return 5 s → identical; hover over Start / Config 4 s → identical
  (shots/sakura-virgl2-{click-start5,return5,down-return5,
  hover-start,hover-config}.png, all md5 df642177…).
- VERDICT: the render stack changes NOTHING for input. virgl is now
  EXCLUDED alongside CPU model, audio clock, DLL gaps, device
  creation, rendering itself, and X/focus delivery (§§K–P). The
  engine does not even react to mouse hover, i.e. it is not polling
  pointer position at the title. The block sits inside the engine's
  input handling (GetAsyncKeyState/GetCursorPos/message-pump path
  per import analysis; DI never acquired) regardless of GL stack.
  Sakura title-input remains OPEN with no remaining environment
  axis identified on this line.

## V. Sakura no Toki — SOLVED: a window manager was the missing piece (ESTABLISHED)

Run: tag sakura-virgl3, config IDENTICAL to §U (launch-var.sh,
prefix sakura-s1, Q32_CPU=max, GALLIUM_DRIVER=virpipe, compat virgl
server pid 14980, GLX probe re-verified err=0; log
logs/var-sakura-virgl3.log). Title reached ≤110 s
(shots/sakura-virgl3-t110.png, md5 df642177…, same frame as §U).
Then, mid-run, ONE variable changed: **twm started on DISPLAY :114**
(pid 15289, LC_ALL=C). twm reparented the game window (position
28,23 → 28,42, title bar visible; shots/sakura-virgl3-twm1.png).
Input retest (menu coordinates shifted +19 px by the frame):
- Held click on Start (982,601) 5 s → STORY ENTERED: prologue text
  pages (「La gazza ladra（泥棒カササギ）…」;
  shots/sakura-virgl3-twm-click5.png).
- Held Return 5 s → text ADVANCED to the next page
  (shots/sakura-virgl3-twm-return5.png).
- Further click/Return advances: in-game scene with full VN UI —
  静流「いらっしゃい」(shots/sakura-virgl3-story1.png) → interior
  scene, two sprites, dialog「あ、いや、キマイラの店主さんが
  おかえりだって聞いていたので……」(shots/sakura-virgl3-story3.png).
  Multiple scenes, sustained progression, game stable.
A/B discipline: §U (same stack/prefix, NO WM) = every input and
hover byte-identical dead; §§K–P (llvmpipe, no WM) = dead. WM
presence is the only changed variable. **VERDICT: Sakura no Toki
title input is FIXED, environment-side: run a window manager on
the game display.** Generic fix for the win32 environment.
Mechanism (HYPOTHESIS, consistent with all evidence, not proven at
API level): the engine gates input polling on window
activation/foreground state. On bare Xvfb there is no activation:
xdotool windowactivate fails ("windowmanager claims not to
support _NET_ACTIVE_WINDOW"), no WM_TAKE_FOCUS is ever delivered,
so Wine's window is never activated and the engine ignores input
even though KeyPress events reach Wine (§P +event). twm's ICCCM
focus/activation supplies what the engine was waiting for.
Remaining trivia (not blockers): whether activation also fixes
the title on llvmpipe (untested — virgl was the test stack; the
gate is render-independent per the A/B), and which exact Win32
signal the engine keys on (WM_ACTIVATE vs foreground vs focus).
