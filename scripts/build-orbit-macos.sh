#!/bin/bash
set -euo pipefail

task_repository_dir="$(cd "$(dirname "$0")/.." && pwd)"
cd "$task_repository_dir"
if [[ "$(uname -s)" != Darwin ]]; then
  echo 'This build requires macOS.' >&2
  exit 1
fi

task_rust_flags=(
  "--remap-path-prefix=$HOME=/build/home"
  "--remap-path-prefix=$task_repository_dir=/build/orbit-desk"
  "--remap-path-prefix=${CARGO_HOME:-$HOME/.cargo}=/build/cargo"
  "--remap-path-prefix=${RUSTUP_HOME:-$HOME/.rustup}=/build/rustup"
)
export CARGO_ENCODED_RUSTFLAGS="$(IFS=$'\x1f'; printf '%s' "${task_rust_flags[*]}")"
export CARGO_PROFILE_RELEASE_DEBUG=0
export CARGO_PROFILE_RELEASE_STRIP=debuginfo
export CFLAGS="${CFLAGS:-} -ffile-prefix-map=$HOME=/build/home"
export CXXFLAGS="${CXXFLAGS:-} -ffile-prefix-map=$HOME=/build/home"
export NODE_USE_ENV_PROXY=1

task_target="$(rustc -vV | sed -n 's/^host: //p')"
case "$task_target" in
  aarch64-apple-darwin|x86_64-apple-darwin) ;;
  *) echo 'A macOS Rust host toolchain is required.' >&2; exit 1 ;;
esac

pnpm prebuild "$task_target"
pnpm tauri build --target "$task_target" --bundles app \
  --config '{"bundle":{"createUpdaterArtifacts":false,"macOS":{"signingIdentity":"-"}}}'
