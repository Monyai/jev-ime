# CLAUDE.md

## プロジェクト
azooKey-Windows のフォーク。Jev（TypeSafe）を使った日英混在入力・誤字補正・文脈変換のIMEを目指す。
タスクは docs/TASKS.md、構造は docs/ARCHITECTURE.md を参照。

## 環境の制約
- 作業環境はLinux。TSFの実動作は確認できない。
- ローカルでの確認は次の2つ。
  - ロジック: `cargo test -p ime-core`（Windows非依存クレート）
  - 型チェック: `cargo check --target x86_64-pc-windows-msvc`（必要なら cargo-xwin）
- Windowsのフルビルドは GitHub Actions で行う。push後はActionsの結果を確認し、失敗したらログを読んで直す。

## ルール
- 入力処理のロジック（未確定バッファ、キーごとの状態遷移、確定判定）は ime-core に置き、windowsクレートに依存させない。
- TSF側は ime-core の結果（「入力を消費するか」「表示する文字列」「確定する文字列」「コンポジションを終了するか」）を反映するだけにする。
- バグ修正は、まず再現するテストを書き、失敗を確認してから直す。原因を特定せずに推測で直さない。
- TSFのDLLはアプリのプロセス内で動く。panicはアプリを落とすので、unwrap()や範囲外インデックスを新しく書かない。
- 1タスク1ブランチ1PR。PR本文に「変更内容」「テスト結果」「実機での確認手順」を書く。
- upstream（fkunn1326/azooKey-Windows）へのPRは作らない。
- APIキーなどの秘密情報をコミットしない。Jevのキーは環境変数 TYPESAFE_API_KEY から読む。
- APIキーが必要になったら、自分で探したり代わりを用意したりせず、メンテナーに聞いて止まる。キーの値をチャット・ログ・PRに出さない。
- このリポジトリは公開されている。PR・コミット・ファイルに個人名やセッションURLなどの個人に紐づく情報を書かない（コミットやPRに Claude-Session などのセッションURLを付けない）。
- フェーズの終わりで必ず止まり、報告して指示を待つ。

## 仕様の基準
キー操作の挙動は、迷ったらMS-IMEとGoogle日本語入力の標準設定に合わせる。
