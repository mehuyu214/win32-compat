# compat line state (overnight analysis, KK order 2026-11-13 23:56 JST)

status: RUNNING (boot work done for the night; awaiting parent direction)
phase: Bisection complete — Majikoi SOLVED at max,-avx2; Sakura title-input still OPEN (virgl axis proposed)
last_update: 2026-11-14 02:22 JST

Hold window: 00:42–00:52 JST (coordination hold; released — listen deliverable recorded as win32-perf/logs/virgl13-story-listen.mp4, 299.93 s, probe 3 delivery 0.969).

Done tonight (detail in RESULTS.md §§D–S):
- Majikoi SOLVED twice over: (1) Nehalem — verified to first dialog; (2) max,-avx2 — verified to first dialog (higher cap, more perf headroom). Fault = a CLASS of illegal instructions (c000001d) in GL-stack mmap code at ≥2 addresses (early 0x520C64B7, late 0x53C8441F). Early needs AVX2+FMA; late needs AVX2 (not FMA, not AVX512F). Recommended spec: Q32_CPU=max,-avx2 via compat-local tools/q32sup-var.
- Key infra finding: stock q32sup82 hardcodes qemu-i386-static + `-cpu max` into every child wrapper (old QEMU_CPU/QEMU_BIN variant results invalid — pentium3 run struck). softpipe alone does NOT fix Majikoi.
- Sakura: white-window verdict REVISED — engine renders warning + title on the stock stack; warning→title advance is a TIMER. Title menu ignores all input (Return/click/Down+Return/Space, 5 s holds, xtest) on stock and Nehalem. +dinput: engine never acquires keyboard/mouse (joystick enum only); exe input path is GetAsyncKeyState/GetCursorPos/message pump. +event: KeyPress DOES reach Wine's window — block is inside the engine. Excluded: CPU model, audio clock (real PA streams live, still no response), DLL gaps, device creation, rendering, X/focus delivery. Remaining axis: virgl stack (needs perf-line coordination).
- Own PA daemon up (port 47140, sink game114, pid 24795, logs/pulseaudio.log) — idle; shared sysroot32 has NO i386 libpulse, so PA runs need LD_LIBRARY_PATH → win32-perf/libs32.

No game processes running now. Xvfb :114 up (pid 3905). Perf line untouched.

Open items for the parent / next session:
1. Sakura virgl test (coordination with perf line — their server/socket).
2. RE:D Cherish retest under max,-avx2 (KK order needed — outside tonight's two titles).
3. Sanoba/Stella Nehalem regression check (proposal input only).
4. Late-crash co-factor X (BMI2? AVX512BW?) — optional, low value now that max,-avx2 works.
