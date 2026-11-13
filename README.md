# win32-compat — 32bit Windows ゲーム互換性解析

GPU のない VM 上で、無改造の 32bit Windows ゲームを動かすための互換性解析記録。
スタックは qemu-i386（ユーザモード）＋ Wine 11.21（32bit, Kron4ek）＋ 独自の ptrace/seccomp スーパバイザ q32sup ＋ i386 sysroot。
姉妹リポジトリ: [win32-env](https://github.com/mehuyu214/win32-env)（環境一式）／ [win32-perf](https://github.com/mehuyu214/win32-perf)（描画性能ライン）。

ゲーム本体のデータは含まない。スクリーンショットは検証証拠。独自コードは MIT。

## 結果サマリ（2026-11-14 夜間解析）

### マジコイ体験版 — SOLVED
- 落下の正体： WGL コンテキスト生成後に GL スタックの mmap コードで起きる不正命令（c000001d）が2箇所。
- 切り分け： 序盤の落下は AVX2＋FMA、後半の落下は AVX2＋未特定の共犯が必要。
- 作業仮説： AVX2 が広告されていると llvmpipe の JIT が吐く AVX2 世代の命令を、qemu-i386 8.2.2 の TCG が誤訳している。
- **実証済みの対策： ゲスト CPU を `max,-avx2` にする**（互換ライン独自の `tools/q32sup-var` 経由）。ロゴ→タイトル→本編→最初の台詞まで到達、約8分クラッシュなし。Nehalem 固定でも動くが余裕は `-avx2` の方が上。
- 付随発見： 純正 q32sup は子ラッパに `-cpu max` をハードコードしており、過去の CPU バリアント実験はすべてゲームに届いていなかった（無効）。`q32sup-var` は環境変数で CPU／qemu を差し替え可能にした改良版。

### サクラノ刻体験版 — タイトル到達、入力が残件
- 「白画面ハング」の旧判定は誤り。実際は起動し、Attention 画面を経て**タイトル画面まで到達**する（警告→タイトルはタイマー遷移で、無入力到達を実証）。白かったのは約0.4fps の低速フェード途中だった。
- 本当の問題： タイトルが入力を一切受けない。+event トレースで KeyPress が Wine のゲームウィンドウに届くことまで証明済み。エンジンは DirectInput のキーボード／マウスを取得せず、入力経路は GetAsyncKeyState／GetCursorPos／メッセージポンプ。
- 除外済み： CPU モデル、音声クロック（実 PulseAudio）、DLL ロード欠落、描画、X／フォーカス配送。
- 残る軸： virgl レンダリングスタックでの試験（未実施、perf ラインとの調整が必要）。

## ファイル
- `RESULTS.md` — 解析の全記録（§§D–S が今回分。established／excluded／hypothesis を分離）
- `compat-state.md` — ラインの現状態と残件
- `DIAG-PLAN.md` — 診断計画
- `scripts/` — 起動・診断スクリプト（`launch-var.sh` が可変 CPU 版）
- `tools/q32sup-var.c` — スーパバイザ改良版のソース（ビルド済みバイナリも同梱）
- `shots/` — 証拠スクリーンショット（マジコイ： タイトル／到達台詞／切り分け経過、桜ノ刻： フェード経過とタイトル）
- `logs/` — 診断ログ抜粋
