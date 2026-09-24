# TASKS

## フェーズ0：調査
- リポジトリを読み docs/ARCHITECTURE.md を作成する（コード変更なし）

## フェーズ1：CI構築
- 既存の .github/workflows を活かし、windows-latest で次を行うワークフローを作る
  - Rust、Swift for Windows（6.0以上）、protoc、Node.js、Inno Setup、cargo-make のセットアップ
  - サブモジュール込みのcheckout
  - `cargo make build --release` とインストーラー生成
  - azookey-setup.exe を Artifact としてアップロード（ファイル名にコミットSHAを含める）
- トリガーはPRと手動実行（workflow_dispatch）
- この時点の master でビルドが通ることを確認する
- 完了条件：Actionsが緑で、Artifactがダウンロードできる
- → メンテナーはこの時点のインストーラーで、既知バグがmasterでも再現するか確認する

## フェーズ2：ロジックの切り出し
- 入力処理の状態管理を新クレート ime-core に移す
  - 未確定バッファは区間のリストとして持つ：`Segment::Romaji(String) | Segment::Literal(String)`
  - キーイベントを受け取り、「消費するか / 表示文字列 / 確定文字列 / コンポジション終了」を返す純粋な関数にする
  - 変換エンジンの呼び出しは trait で抽象化し、テストではモックを使う
- 既存の挙動は変えない（リファクタリングのみ）
- 完了条件：`cargo test -p ime-core` が通り、Actionsのビルドも緑

## フェーズ3：既知バグの修正（1件1PR、この順番）

### 3-1 空の状態でEnterを押すとアプリごと落ちる
- 再現手順：日本語入力で「Wiんどws」のように入力 → Backspaceで全部削除 → Enter
- 期待動作：
  - Backspaceで未確定文字列が空になったら、その場でコンポジションを終了し状態をリセット
  - 未確定文字列がないときのEnterはIMEで消費せずアプリに渡す
- 保険：COMの入口（キーイベントシンク等）を catch_unwind で包み、panic時はエラーを返すだけにする。profileが panic = "abort" なら見直す
- 原因となった箇所をPRに明記する

### 3-2 ライブ変換のオフとスペース変換
- 設定に「ライブ変換」フラグを追加し、デフォルトはオフ
- オフのとき：打鍵中はローマ字→ひらがなのみ表示し、変換エンジンを呼ばない
- Space：1回目で変換して第1候補を表示、2回目以降は次の候補へ。Enterで確定、Escでひらがなに戻る
- Spaceでの変換処理は、将来Jev層を差し込めるように1関数にまとめる

### 3-3 Shift＋英字で英字入力
- Shift＋英字を押した時点で英字サブモードに入り、その文字以降は小文字も含め Segment::Literal に入れる
- SpaceまたはEnterでサブモードを抜ける
- 例：「Shift+W, i, n, d, o, w, s」→ 「Windows」（「Wiんどws」にならない）
- Literal区間は変換エンジンに渡さずそのまま残す

## フェーズ4：Jev層の準備（アクセス取得後に指示）
- 左文脈（leftSideContext）をZenzaiに渡す（未対応の場合）
- ime-core に日英分割・誤字候補生成とJevの判定を追加する
- テストケース：「claudedekonosagyouwoonegaisitai」→「claudeでこの作業をお願いしたい」、「claudeddekkonosahyouwoonegaisita」→「claudeでこの作業をお願いした」
