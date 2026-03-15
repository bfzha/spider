"""
Crate universe configuration for Spider project.
This file defines the external Rust crate dependencies from crates.io.
Generated dependencies are resolved from Cargo.lock.
"""

load("@rules_rust//crate_universe:defs.bzl", "crates_repository")

def crate_repositories():
    """
    Define all external crate dependencies from crates.io.
    Uses crate_universe to generate Bazel targets from Cargo metadata.
    """
    crates_repository(
        name = "crates_io",
        # The lockfile contains exact versions of all dependencies
        cargo_lockfile = "//:Cargo.lock",
        # All Cargo.toml manifests in the workspace
        manifests = [
            "//:Cargo.toml",
            "//spider:Cargo.toml",
            "//spider_cli:Cargo.toml",
            "//spider_worker:Cargo.toml",
            "//spider_agent:Cargo.toml",
            "//spider_agent_types:Cargo.toml",
            "//spider_agent_html:Cargo.toml",
            "//spider_utils:Cargo.toml",
            "//benches:Cargo.toml",
            "//examples:Cargo.toml",
        ],
        # Optional: pinned versions for reproducibility
        # These can be overridden for security updates
        supported_targets = [
            "aarch64-apple-darwin",
            "aarch64-apple-ios",
            "aarch64-linux-android",
            "aarch64-unknown-linux-gnu",
            "i686-apple-darwin",
            "i686-pc-windows-msvc",
            "i686-unknown-linux-gnu",
            "wasm32-unknown-unknown",
            "wasm32-wasi",
            "x86_64-apple-darwin",
            "x86_64-apple-ios",
            "x86_64-pc-windows-msvc",
            "x86_64-unknown-linux-gnu",
        ],
    )