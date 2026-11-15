# QRUPPO trial test — qruppo-test line (:117)

Goal: download DMM trial qruppo_0006t.zip, run unmodified on the 32-bit
qemu-i386 + q32sup + Wine 11.21 stack, play it, capture 60 s @20fps,
score with KK's picture-level method (tools/score_frames.py).

## Download
- URL: https://sample9.dmm.co.jp/digital/pcgame/qruppo_0006/qruppo_0006t.zip
- Size: 2,617,880,772 bytes (= server Content-Length; first attempt cut by a
  600 s timeout at 1,397,305,344 B, resumed with curl -C - to completion)
- sha256: 32394716c054239d0c90c44efccbf6f0c79df14fae836d1952695361f78f8f4b

## Identification
- Title: 『抜きゲーみたいな島に住んでる貧乳はどうすりゃいいですか？Remaster』
  体験版 ver.メルクオリア, Ver.0.52mh, by Qruppo (readme.txt, release 2024/03/22)
  ("NUKITASHI" Remaster trial)
- Plain folder trial (no installer): NUKITASHI_TRIAL.exe + NUKITASHI_TRIAL.pfs
  (+ .pfs.000/.001/.002, ~2.27 GB data), movie/*.dat x4, d3dcompiler_47.dll,
  iarsys64.dll, LICENSE.txt, readme.txt.
- **PE check: NUKITASHI_TRIAL.exe = PE32+ (x86-64, 64-bit)**; iarsys64.dll also
  PE32+; bundled d3dcompiler_47.dll is PE32.
- Consequence: the q32sup + qemu-i386 + Wine32 stack CANNOT run this title
  (PE32 only). Route taken per brief: native 64-bit Wine —
  ~/workspace/vn-trials/wow64/wine-11.21-amd64-wow64/bin/wine (native x86-64
  ELF, `wine --version` OK on this VM). Host libGL.so.1 present; libEGL.so.1
  missing on host (VM-restart wipe) → LD_LIBRARY_PATH borrows the perf line's
  restored copy in win32-perf/virgl-libs. Fresh prefix: prefix64/, DISPLAY :117.

## Boot / play
- Route: NATIVE Wine64 (no qemu/supervisor) — vn-trials/wow64
  wine-11.21-amd64-wow64, fresh prefix `prefix64/` on DISPLAY :117,
  LANG=ja_JP.UTF-8 + LOCPATH, ALSA null, LD_LIBRARY_PATH borrowing the perf
  line's restored libEGL (virgl-libs) since the host copy was wiped.
- Prefix-init caveat (measured): a from-scratch `wineboot --init` HANGS on
  this VM — rundll32 setupapi InstallHinfSection DefaultInstall blocks in
  anon_pipe_read at ~0% CPU indefinitely (reproduced twice: full env and
  minimal env; system32 file count frozen at 790). Workaround used: copied
  the pre-existing booted vn-trials/wineprefix-wow64 into prefix64/
  (read-only borrow; contents verified — `wine cmd /c echo` OK in ~6 s).
- **BOOT: ✅ Title screen reached in <45 s from launch**, rendered correctly
  (full key visual, menu NEWGAME/LOAD/CONTINUE/SCENARIOS/EXTRA/CONFIG/EXIT,
  "Ver.0.5.3 mh 体験版"). caps/shot-title.png. Game log: 0 errors/asserts.
- Input (native route differs from the qemu stack):
  - Mouse: focus + click #1 on NEWGAME → hover highlight only; click #2 →
    ACTIVATED (black transition → game start). So plain clicks DO work here,
    they just needed the hover/focus pass first.
  - AUTO: clicked the ▶ bottom-bar button once — no dialogue advance within
    ~28 s (either that button is not AUTO or auto-wait is long; unverified).
  - Held keys: holdkey Return 1.2 s x3 advanced multiple lines reliably,
    including a scene change to a CG + new text. caps/shot-after-cap.png.
- **GAMEPLAY REACHED**: first line 「それは、一振りのバイブであった。」(caps/
  shot-gameplay-first.png), advanced to 「だがひとたび強い衝撃を受ければ、
  中に流しこまれた特殊液"d10o"の分子同士が結合し、鋼と化す。」 + CG.
- Stability: game pid alive the whole session, ~55-58% CPU (native, no
  emulation), no crashes. Instance closed by me after the run (wineserver -k).

## Capture + score
- Capture: caps/cap-qruppo-60.mkv — ffmpeg x11grab :117, 1280x720 @20fps,
  exactly 60.000 s / 1200 frames, 492,797 B. Content: ~28 s on the first
  dialogue line (background sparkle animation; AUTO attempt did not advance),
  then held-Enter advances in the back half (multiple lines + one scene
  change, MAD spike 36.8).
- Scorer: the canonical ~/workspace/win32-perf/tools/score_frames.py as it
  stands now = **v2 thresholded-MAD** (160x90 gray, frame counts if MAD >
  0.05; the v1 exact-hash version was retired by the perf line as
  noise-inflated). Outputs: caps/cap-qruppo-60-scores.{json,csv,png}.
- **SCORE: mean 0.717 pts/s, median 1.0 pts/s, seconds >=10 pts/s: 0/60,
  zero-point seconds: 22/60, max 3 pts/s.** MAD median 0.0006 (most frames
  near-identical at picture level).
- Reading: this is a dialogue-dwell-heavy VN scene — long static text with a
  sparse particle background — so the picture-change score is low even though
  the engine runs natively at full speed (no QEMU tax). Same order as the
  perf line's v2 re-scores of Sanoba on llvmpipe (env 0.417, base2 0.567
  pts/s). The score measures picture change, not engine frame rate; a fair
  smoothness comparison needs an animation-heavy scene (OP/movie), not timed
  in this run.
