#!/bin/bash
# Claude Code on the web 用のセッション開始フック。
# Linux上で `cargo check --target x86_64-pc-windows-msvc` を通すために
# protoc（crates/shared の build.rs が使う）と Windows 向け Rust ターゲットを入れる。
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

if ! command -v protoc >/dev/null 2>&1; then
  if ! apt-get install -y -qq protobuf-compiler >/dev/null 2>&1; then
    apt-get update -qq >/dev/null 2>&1
    apt-get install -y -qq protobuf-compiler >/dev/null
  fi
fi

if ! rustup target list --installed | grep -qx x86_64-pc-windows-msvc; then
  rustup target add x86_64-pc-windows-msvc
fi
