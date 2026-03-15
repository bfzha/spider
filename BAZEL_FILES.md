# Bazel 迁移新增文件说明

本文档详细说明了从 Cargo 构建系统迁移到 Bazel 构建系统时新增的所有文件及其作用。

---

## 核心配置文件

| 文件 | 作用 |
|------|------|
| **`MODULE.bazel`** | Bazel 模块定义（Bzlmod 模式），声明项目名称、版本、依赖（rules_rust、platforms 等） |
| **`MODULE.bazel.lock`** | 锁定依赖精确版本，确保可重复构建（类似 Cargo.lock） |
| **`WORKSPACE.bzlmod`** | 工作区配置，设置 Rust 工具链、crate_universe（Cargo 依赖转换）、Go 工具链等 |
| **`BUILD.bazel`** (根目录) | 定义 Feature Flags（40+ 个开关），如 `chrome`、`openai`、`io_uring` 等 |

---

## 辅助配置文件

| 文件 | 作用 |
|------|------|
| **`crates.bzl`** | crate_universe 配置，将 `Cargo.lock` 中的依赖转换为 Bazel 目标 `@crates_io//:xxx` |
| **`features.bzl`** | Feature Flag 文档，记录所有特性的默认值、依赖关系、rustc flags |
| **`.bazelrc`** | Bazel 运行配置，定义 `--config=chrome`、`--config=release` 等快捷方式 |
| **`.bazelignore`** | 忽略文件，排除 Cargo 构建产物等 |

### 各文件详解

#### `MODULE.bazel`

Bazel 6.0+ 引入的新模块系统（Bzlmod），替代传统的 WORKSPACE 依赖管理方式：

```starlark
module(
    name = "spider",
    version = "2.47.22",
)

# 声明依赖
bazel_dep(name = "rules_rust", version = "0.63.0")
bazel_dep(name = "platforms", version = "1.0.0")
bazel_dep(name = "bazel_skylib", version = "1.8.2")

# Rust 工具链配置
rust = use_extension("@rules_rust//rust:extensions.bzl", "rust")
rust.toolchain(edition = "2021", versions = ["1.94.0"])

# 从 Cargo.lock 导入依赖
crate = use_extension("@rules_rust//crate_universe:extension.bzl", "crate")
crate.from_cargo(name = "crates_io", cargo_lockfile = "//:Cargo.lock", ...)
```

#### `WORKSPACE.bzlmod`

传统工作区配置文件，在 Bzlmod 模式下作为补充：

- 加载 `rules_rust` 和 Rust 工具链
- 配置 `crate_universe` 从 Cargo.lock 生成依赖
- 预留 Go 工具链配置（已注释）
- 平台定义和 Skylib 工具库

#### `crates.bzl`

定义 `crates_repository`，将 Cargo 依赖映射到 Bazel：

```starlark
crates_repository(
    name = "crates_io",
    cargo_lockfile = "//:Cargo.lock",
    manifests = [
        "//:Cargo.toml",
        "//spider:Cargo.toml",
        // ... 其他 Cargo.toml
    ],
    supported_targets = [
        "x86_64-unknown-linux-gnu",
        "aarch64-apple-darwin",
        // ... 其他平台
    ],
)
```

#### `features.bzl`

集中管理所有 Feature Flags 的定义：

```starlark
FEATURE_FLAGS = {
    "chrome": {
        "default": False,
        "description": "Enable Chrome browser automation",
        "rustc_flag": 'feature="chrome"',
        "deps": ["chromey", "base64", "rand", ...],
        "implies": ["serde", "cookies"],
    },
    "openai": { ... },
    "io_uring": { ... },
    // ...
}
```

#### `.bazelrc`

Bazel 命令行配置，提供快捷方式：

```bash
# 启用 Chrome 特性
bazel build //spider:spider --config=chrome

# 发布构建
bazel build //spider_cli:spider --config=release

# 平台特定构建
bazel build //spider:spider --config=linux
```

---

## 各模块构建文件

| 文件 | 作用 |
|------|------|
| **`spider/BUILD.bazel`** | 核心爬虫库构建规则 |
| **`spider_cli/BUILD.bazel`** | CLI 工具构建规则 |
| **`spider_worker/BUILD.bazel`** | Worker 服务构建规则 |
| **`spider_agent/BUILD.bazel`** | Agent 库构建规则 |
| **`spider_agent_types/BUILD.bazel`** | Agent 类型定义构建规则 |
| **`spider_agent_html/BUILD.bazel`** | HTML 处理库构建规则 |
| **`spider_utils/BUILD.bazel`** | 工具库构建规则 |
| **`benches/BUILD.bazel`** | 基准测试（支持 Rust + Go） |
| **`examples/BUILD.bazel`** | 示例代码构建 |

### 构建文件示例

```starlark
# spider_cli/BUILD.bazel
rust_binary(
    name = "spider",
    srcs = glob(["src/**/*.rs"]),
    crate_root = "src/main.rs",
    deps = [
        "//spider:spider",
        "@crates_io//:clap",
        "@crates_io//:tokio",
        # ...
    ],
    rustc_flags = select({
        "//:chrome_enabled": ["--cfg", 'feature="chrome"'],
        "//conditions:default": [],
    }),
)
```

---

## 文档文件

| 文件 | 作用 |
|------|------|
| **`BAZEL_README.md`** | Bazel 使用指南（中文），包含构建命令、Feature Flags 说明、常见问题 |
| **`BAZEL_MIGRATION.md`** | 迁移复盘记录，记录迁移过程、遇到的问题和解决方案 |

---

## 辅助脚本与文件

| 文件 | 作用 |
|------|------|
| **`patch_module.sh`** | 模块补丁脚本 |
| **`all_crates.txt`** | 所有 crate 列表 |

---

## Bazel 输出目录（应在 .gitignore 中排除）

| 目录 | 作用 |
|------|------|
| **`bazel-bin`** | 编译输出（符号链接） |
| **`bazel-out`** | 实际构建产物 |
| **`bazel-spider`** | 工作区符号链接 |
| **`bazel-testlogs`** | 测试日志 |

---

## 为什么迁移到 Bazel？

1. **多语言支持** - 统一构建 Rust + Go + Node.js
2. **增量构建** - 沙盒和缓存机制实现秒级增量编译
3. **可重复构建** - 严格的依赖隔离，确保构建结果一致
4. **企业级特性** - 支持分布式缓存、远程执行

---

## Cargo 与 Bazel 共存

两套构建系统可以同时使用：

```bash
# Cargo 方式
cargo build --release

# Bazel 方式
bazel build //spider_cli:spider --config=release
```

依赖管理：
- **Cargo**: `Cargo.toml` 和 `Cargo.lock` 仍然是依赖声明的源
- **Bazel**: `crate_universe` 从 `Cargo.lock` 生成 Bazel 依赖

更新依赖流程：
```bash
# 1. 更新 Cargo.toml
cargo add <package>

# 2. 更新 Cargo.lock
cargo update

# 3. Bazel 会自动使用新的依赖
bazel build //spider:spider
```

---

## 常用命令对照

| 操作 | Cargo | Bazel |
|------|-------|-------|
| 构建库 | `cargo build -p spider` | `bazel build //spider:spider` |
| 构建 CLI | `cargo build -p spider_cli` | `bazel build //spider_cli:spider` |
| 发布构建 | `cargo build --release` | `bazel build //... --config=release` |
| 启用特性 | `cargo build --features chrome` | `bazel build //... --config=chrome` |
| 运行测试 | `cargo test` | `bazel test //...` |
| 清理 | `cargo clean` | `bazel clean` |
| 查看依赖 | `cargo tree` | `bazel query "deps(//spider:spider)"` |

---

## 相关链接

- [Bazel 官方文档](https://bazel.build/)
- [rules_rust](https://github.com/bazelbuild/rules_rust)
- [Bzlmod 迁移指南](https://bazel.build/external/migration)