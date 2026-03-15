#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 4 ]]; then
    echo "usage: $0 <workspace-manifest> <cargo-package> <binary-name> <output>" >&2
    exit 1
fi

manifest_path="$1"
package_name="$2"
binary_name="$3"
output_path="$4"

target_dir="$(dirname "$output_path")/cargo-target"
mkdir -p "$target_dir"

if [[ -z "${HOME:-}" ]]; then
    HOME="$(getent passwd "$(id -u)" | cut -d: -f6)"
    export HOME
fi

export CARGO_HOME="${CARGO_HOME:-$HOME/.cargo}"
export RUSTUP_HOME="${RUSTUP_HOME:-$HOME/.rustup}"
export PATH="$CARGO_HOME/bin:$PATH"

if [[ -f "$CARGO_HOME/env" ]]; then
    # rustup installs this helper to populate PATH and related variables.
    # In Bazel actions HOME is often unset, so we source it only after
    # establishing HOME/CARGO_HOME explicitly.
    source "$CARGO_HOME/env"
fi

if ! command -v cargo >/dev/null 2>&1; then
    echo "cargo is required on PATH for Bazel release builds" >&2
    exit 1
fi

export CARGO_INCREMENTAL=0

cargo build \
    --manifest-path "$manifest_path" \
    --package "$package_name" \
    --bin "$binary_name" \
    --release \
    --locked \
    --target-dir "$target_dir"

cp "$target_dir/release/$binary_name" "$output_path"
