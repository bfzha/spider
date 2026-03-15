# Spider 项目 Bazel 迁移汇总与复盘记录

本文档主要记录了将 `spider` 原有的 Cargo 构建系统平滑且完全地迁移（或并行支持）到 **Bazel** 构建系统的全过程。通过一系列调试和修复，目前全工作区（`bazel build //...`）已经达到了 **100% 构建成功 (Exit Code 0)** 的状态。

---

## 1. 迁移方法论 (Methodology)

本次迁移采用的核心策略如下：
1. **基础设施依赖**：借助 `@rules_rust` 管理 Rust 编译规则，并通过 `bzlmod` (`MODULE.bazel`) 结合 `cargo_universe` 完成对外部第三方依赖的解析，将其映射为 `@crates_io//:<crate_name>` 的扁平形式。
2. **渐进式迭代验证**：采用了“构建 -> 报错 -> 解析日志 -> 修复依赖链 -> 重试”的闭环策略。通过反复执行 `bazel build //...`，让 Rustc 编译器主动暴露 `BUILD.bazel` 与 `Cargo.toml` 中信息不对等的地方。
3. **严格声明式映射**：在 Cargo 中很多隐式行为（例如模块的自动发现、特性的隐式继承），在 Bazel 中都需要转变为**显式声明**（Explicit Declaration）。

---

## 2. 所做的核心改变 (Key Changes Made)

整个项目按组件维度进行了大量的构建规则修复：

### 2.1 `spider` (核心库)
* **添加缺失的系统与底层依赖**：在 `spider/BUILD.bazel` 中，为底层新增了 `"@crates_io//:libc"`、`"@crates_io//:flexbuffers"`。
* **特性标志 (Feature Flags) 同步**：补全了 `spider` 库编译所必须的 `--cfg feature="..."` 标志（如 `flexbuffers`），使得下游依赖此特性的 `spider_worker` 能够被成功提供 API。

### 2.2 `spider_cli` (命令行套件)
* **由单文件转为全源码扫描**：原本 `BUILD.bazel` 中仅声明了 `srcs = ["src/main.rs"]`。由于 CLI 引用了内部的 `cli.rs` 和 `args.rs` 等模块，导致了 `E0583 (file not found for module)` 报错。
* **修复方法**：引入 Bazel 的 Glob 机制，将其修改为 `srcs = glob(["src/**/*.rs"])`，确保所有的源码文件一并喂给 `rustc` 解析。

### 2.3 `spider_agent` & `spider_utils` (工具与代理层)
* **修复 Proc Macro 声明错位**：在 `spider_agent/BUILD.bazel` 中，原本将宏库 `"@crates_io//:async-trait"` 放到了 `deps` 里，在 Bazel 中会导致它被当做普通依赖来构建。我们将其移到了**专用的 `proc_macro_deps`** 列表中。
* **Python 数组语法及幽灵依赖**：清理了 `spider_utils` 中破损的 Bazel List 语法，并剔除了未被 Cargo Universe 正确导出的可选依赖 `indexmap`，消除了 Unresolved 的解析报错。

### 2.4 `examples` & `benches` (示例与基准测试)
* **海量二进制目标的精确导向**：示例目录下有几十个单一的可执行文件（如 `scrape`, `serde_example` 等）。针对构建中出现的 `E0432`, `E0463` 等依赖缺失错误，分别为对应的 target 手动注入了 `"@crates_io//:env_logger"`, `"@crates_io//:flexbuffers"` 以及局部依赖 `"//spider_utils:spider_utils"`。
* **多模块测试修复**：在基准测试 `benches/BUILD.bazel` 中，`crawl.rs` 包含外部模块 `go_colly` 等，原配置无法读取到。通过 `srcs = glob(["*.rs"])` 加上明确指向入口文件 `crate_root = "crawl.rs"` 完美化解。

---

## 3. 面临的挑战与 Debug 总结 (Debugging & Troubleshooting)

由于 Bazel 提倡的是**气系隔离（Hermetic Build）**和**严格边界**，通常在 Cargo 自动包含的功能，在 Bazel 下会频繁报错。遇到并解决的典型问题包括：

### 问题 A：未解析的模块 / 包 (Error `E0432`, `E0433`, `E0463`)
* **症状**：`can't find crate for 'xxx'` 或 `unresolved import`。
* **根因**：开发者在 Cargo.toml 声明了依赖，却忘了在 `BUILD.bazel` 中同步写入到对应目标的 `deps` 中。由于 Bazel 的沙盒机制（Linux Sandbox），未在 `deps` 声明的依赖**绝对无法访问**。
* **解决**：找到抛错的文件，定位其属于哪个 Bazel target，然后在 `deps` 中精确加上 `@crates_io//:xxx` 或对应的 `//folder:target`。

### 问题 B：多文件模块的 `srcs` 加载失败 (`E0583`)
* **症状**：报 `file not found for module 'xxx'`，哪怕文件实际上就在同一目录下。
* **根因**：`Cargo` 会从 `main.rs` 出发扫描依赖图并自动调取硬盘文件；而 `Bazel` 必须要在 `srcs` 显式喂给它所有要参与编译的文件列表。如果只写 `["main.rs"]`，其它文件不会被挂载入编译沙盒。
* **解决**：常规的包全量采用 `srcs = glob(["src/**/*.rs"])`，确保一切 Rust 源代码均可见。当有多个主入口并在同一个目录时（如 benches），要配合 `crate_root = "xxx.rs"` 指定入口点。

### 问题 C：特性开关 (Features) 没有打通
* **症状**：某项方法“不存在”，如 `spider_worker` 报错无法引用 `spider::flexbuffers`。
* **根因**：对于具备众多 feature 开关的库（比如本作 `spider`），虽然被依赖，但若被依赖侧的 rule 未传入对应的 `rustc_flags = ["--cfg", "feature=\"...\""]`，那条件编译 `#[cfg(feature = "...")]` 里面的代码将会被无情剔除。
* **解决**：在底层 `rust_library` (比如 spider 自身) 和上层调用方都配置对应的 feature `select` 宏和 flags。

---

## 4. 结论与里程碑
历经上述修复调优后，现在整个包含 **Cargo + bzlmod** 的拓扑双重体系已经被我们对接完毕。
以后凡是依赖、源文件发生变更，只需保持上述对应原则。目前可实现一键秒级解析和增量缓存编译：
```bash
bazel build //...
bazel run //spider_cli:spider -- --help
```
顺利迈入企业级的增量构建时代！