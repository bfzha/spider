# Bazel 迁移与构建说明

本文档说明这个仓库在迁移到 Bazel 之后，当前已经纳入 Bazel 管理的构建内容、各个目标之间的依赖关系、构建时实际会编译哪些东西、目前已经验证到什么程度，以及后续应该按什么顺序继续验收。

这份文档关注的是“Bazel 迁移后的工程结构与构建行为”，不是业务功能说明。

## 1. 这次迁移的目标是什么

这个仓库当前的 Bazel 迁移目标，不是简单把 `cargo build` 包一层，而是把 Rust workspace 的主要构建过程真正迁入 Bazel，让 Bazel 成为统一入口。

当前采用的技术栈是：

- `rules_rust`
- `crate_universe`
- `Bzlmod`

对应的核心入口文件是：

- [MODULE.bazel](/home/zhadainian/scientific_research/spider/MODULE.bazel)
- [BUILD.bazel](/home/zhadainian/scientific_research/spider/BUILD.bazel)
- [bazel/features.bzl](/home/zhadainian/scientific_research/spider/bazel/features.bzl)

这次迁移实际想解决的是下面几件事：

- 用 Bazel 统一管理 Rust workspace 的构建入口
- 把仓库内多个 crate 暴露为明确的 Bazel target
- 让外部 Rust 依赖通过 `crate_universe` 进入 Bazel 依赖图
- 让 `build.rs`、原生库编译、链接步骤也被 Bazel 接管
- 让最终二进制、测试、打包目标都可以按 Bazel 的方式组织和验证

需要特别说明的一点是：

- Bazel 能统一“构建系统”
- 但不会自动把“一个 Linux 二进制”变成“所有平台通用二进制”

也就是说，Bazel 解决的是“怎么为不同平台分别构建”，不是“编一次到处直接跑”。

## 2. 当前已经迁移进 Bazel 的内容

从工程角度看，当前迁移进 Bazel 的内容可以分成三层。

### 2.1 仓库内自己的 Rust 目标

这些是你自己维护的 workspace crate，它们已经有对应的 `BUILD.bazel`：

- `spider`
- `spider_cli`
- `spider_worker`
- `spider_agent`
- `spider_agent_types`
- `spider_agent_html`
- `spider_utils`
- `examples`
- `benches`

对应文件包括：

- [spider/BUILD.bazel](/home/zhadainian/scientific_research/spider/spider/BUILD.bazel)
- [spider_cli/BUILD.bazel](/home/zhadainian/scientific_research/spider/spider_cli/BUILD.bazel)
- [spider_worker/BUILD.bazel](/home/zhadainian/scientific_research/spider/spider_worker/BUILD.bazel)
- [spider_agent/BUILD.bazel](/home/zhadainian/scientific_research/spider/spider_agent/BUILD.bazel)
- [spider_agent_types/BUILD.bazel](/home/zhadainian/scientific_research/spider/spider_agent_types/BUILD.bazel)
- [spider_agent_html/BUILD.bazel](/home/zhadainian/scientific_research/spider/spider_agent_html/BUILD.bazel)
- [spider_utils/BUILD.bazel](/home/zhadainian/scientific_research/spider/spider_utils/BUILD.bazel)
- [examples/BUILD.bazel](/home/zhadainian/scientific_research/spider/examples/BUILD.bazel)
- [benches/BUILD.bazel](/home/zhadainian/scientific_research/spider/benches/BUILD.bazel)

### 2.2 外部 Rust 依赖

这些依赖来自 crates.io，不再由 Cargo 在构建时临时解析，而是由 `crate_universe` 根据 Cargo 元数据生成 Bazel 依赖图。

它们的来源是：

- [Cargo.toml](/home/zhadainian/scientific_research/spider/Cargo.toml)
- [Cargo.lock](/home/zhadainian/scientific_research/spider/Cargo.lock)
- [MODULE.bazel](/home/zhadainian/scientific_research/spider/MODULE.bazel)

例如当前会进入 Bazel 图中的 crate 包括但不限于：

- `tokio`
- `reqwest`
- `serde`
- `chromey`
- `cookie`
- `httpdate`
- `aws-lc-sys`
- `openssl-sys`

### 2.3 原生代码与构建脚本

这个仓库不是纯 Rust 仓库。迁移到 Bazel 之后，真正被接管的不只是 `.rs` 文件编译，还包括：

- crate 的 `build.rs`
- C/C++ 原生代码编译
- 链接器参数
- 平台工具链差异

典型例子有：

- `aws-lc-sys`
- `openssl-sys`
- `zstd-sys`
- `libsqlite3-sys`

所以你在 Bazel 里构建一个 Rust 目标时，底层实际可能会发生：

- Rust 编译
- C 编译
- 头文件搜索路径处理
- build script 环境变量注入
- 原生链接

这也是为什么这次迁移里，很多问题并不是“Rust 源码语法问题”，而是“feature 闭包、依赖图、native toolchain、build.rs 行为”共同决定的。

## 3. 迁移后你真正要编译的东西有哪些

如果从“迁移验收”的角度看，而不是从“仓库里有多少 crate”的角度看，那么你真正需要关心的编译目标主要是下面几类。

### 3.1 用户直接使用的二进制

这是最重要的一层，因为它们才是最终交付物。

- `//spider_cli:spider`
- `//spider_worker:spider_worker`

其中：

- `//spider_cli:spider` 是 CLI 主程序
- `//spider_worker:spider_worker` 是 worker 程序

只要这两个目标没有打通，迁移就不能算完成。

### 3.2 核心库目标

这些是二进制背后的工作库，虽然用户不直接执行，但二进制会依赖它们：

- `//spider:spider_workspace`
- `//spider_agent:spider_agent_workspace`
- `//spider_agent_types:spider_agent_types`
- `//spider_agent_html:spider_agent_html`
- `//spider_utils:spider_utils`

如果这些库目标 feature 选错、依赖没补齐，最终 CLI 或 worker 就会在分析阶段或编译阶段报错。

### 3.3 测试、示例、基准目标

这些不一定影响主二进制是否能生成，但它们是迁移验收的重要部分：

- `spider` 自身的单测和集成测试
- `spider_agent` 的测试和 examples
- `examples/` 下的示例目标
- `benches/` 下的 benchmark 目标

这部分通常不建议一开始就一起打，因为会把问题面拉得太宽。更合理的做法是先把主二进制打通，再逐步扩展。

### 3.4 打包目标

仓库根上还有发布相关 target：

- `//:spider_cli_release`
- `//:spider_worker_release`
- `//:spider_release_archive`

其中：

- `//:spider_cli_release` 实际指向 `//spider_cli:spider`
- `//:spider_worker_release` 实际指向 `//spider_worker:spider_worker`
- `//:spider_release_archive` 负责把发布物收集并打包

从迁移角度看，打包目标应该放在最后验证，因为它依赖前面的二进制目标都稳定之后才有意义。

## 4. 每个关键 Bazel 目标到底会编译什么

这一节是最容易被误解的地方。

很多人会以为执行：

```bash
bazel build //spider_cli:spider
```

就是“编一个 CLI 文件”。实际上不是。Bazel 会编译的是“这个 target 的整棵依赖树”。

### 4.1 `bazel build //spider_cli:spider`

这条命令至少会触发下面几类内容：

- `spider_cli` 二进制本身
- `spider` 库
- `spider_agent` 库（如果当前 feature 集需要）
- `spider_agent_types`
- `spider_agent_html`
- Bazel 依赖图中被选中的外部 crates
- 这些 crates 所需的 `build.rs`
- 相关原生依赖的编译和链接

所以它不是“只编 CLI”，而是“编 CLI 所需的完整闭包”。

你当前已经验证通过的产物路径是：

- [bazel-bin/spider_cli/spider](/home/zhadainian/scientific_research/spider/bazel-bin/spider_cli/spider)

### 4.2 `bazel build //spider_worker:spider_worker`

这条命令逻辑上会触发：

- `spider_worker` 二进制
- `spider` 库在 worker feature 集下的构建
- worker 所需的 workspace crates
- worker 对应的外部 crates 及 native 依赖

它和 CLI 不一定共享同一套 feature 闭包，所以不能因为 CLI 过了，就默认 worker 一定过。

### 4.3 `bazel build //...`

这条命令会尝试构建仓库里所有可分析的 Bazel 目标，通常包括：

- 所有库
- 所有二进制
- 所有测试
- 所有 examples
- 所有 benches
- 根目录上的别名或打包规则

这条命令适合放在迁移后期，而不是早期。原因很简单：

- 早期执行它会把所有问题同时抛出来
- 不利于定位 feature 闭包和依赖图错误
- 不利于区分“主路径已通”与“边角目标未通”

### 4.4 `bazel build //:spider_release_archive`

这条命令重点不是重新发现源码编译问题，而是验证：

- 发布目标依赖是否都能正确生成
- 打包规则是否引用了正确的输出
- 产物收集流程是否闭合

这属于“迁移验收的最后一层”。

## 5. 这次迁移里最关键的技术点是什么

如果只总结一个核心经验，那就是：

- 这个仓库是强 feature-gated 的 Rust 工程
- Bazel 里手工指定 `crate_features` 时，不能想当然地认为它会完全等价于 Cargo 的特性传播

这直接带来了几个实际问题。

### 5.1 feature 开太宽，会把不需要的代码路径也拉进来

之前遇到的大量错误，本质上都不是“源码突然坏了”，而是：

- 给 `spider` 或 `spider_agent` 配了过宽的 feature 集
- 导致 Bazel 尝试编译本来不该进入当前 CLI 路径的模块
- 这些模块再去引用 optional dependency
- 于是开始出现大量 “unresolved crate / unresolved module / type inference” 错误

所以，Bazel 迁移里最重要的事情之一，不是“依赖越全越好”，而是：

- feature 必须收敛到当前目标真正需要的最小闭包

### 5.2 Bazel 里的 feature 需要和 deps 同步维护

在 Cargo 里，feature 和 optional dependency 的传播是 Cargo 负责的。

但在这里，`rust_library(crate_features = [...])` 配的是 Bazel 侧视图。实际效果是：

- 你在 Bazel 打开了某个 feature
- 对应 optional crate 不一定会自动完整地进入 Bazel 的 deps 列表

所以迁移时必须同时看两件事：

- feature 有没有开
- 这个 feature 对应的 crate 有没有真的进入 Bazel 依赖图

### 5.3 有些问题来自 native crate，不是 Rust 代码本身

这次最典型的是 `aws-lc-sys`。

它的问题不是 Rust 源码错误，而是底层 `jitterentropy` 这段 C 代码要求：

- 编译时最终优化等级必须是 `-O0`

而 Bazel/rules_rust/cc-rs 合并出来的 `CFLAGS` 默认会把 `-O2` 追加到后面，导致：

- 前面虽然有 `-O0`
- 但最后一个优化等级仍是 `-O2`
- 最终 C 编译失败

因此才需要在 [MODULE.bazel](/spider/MODULE.bazel) 里用 `crate.annotation` 为 `aws-lc-sys` 单独注入环境变量，把最终优化等级压到 `-O0`。

这个问题说明：

- Bazel 迁移不仅是 Rust BUILD 文件问题
- 还包含 native crate 的 build 行为适配

## 6. 当前已经完成到什么程度

截至目前，已经明确验证通过的是：

- `//spider_cli:spider` 可以在 Linux `x86_64-unknown-linux-gnu` 下成功构建

你已经拿到过成功输出：

- `Target //spider_cli:spider up-to-date`
- `INFO: Build completed successfully`

这意味着以下几点已经成立：

- Bazel 能完成目标分析
- `spider_cli` 当前依赖闭包已经能被 Bazel 正确解析
- 相关 Rust 代码能够编译
- 相关 native crate 能够完成构建
- 最终二进制已经生成

但这还不意味着下面这些也自动成立：

- `//spider_worker:spider_worker` 已通过
- `//...` 已全部通过
- `//:spider_release_archive` 已通过
- Windows 已支持
- macOS 已支持
- Linux 上构建出的产物可以直接在 Windows 运行

这些都必须单独验证。

## 7. 当前成功构建的结果到底意味着什么

你前面已经问过一个关键问题：既然 Bazel 构建成功了，这个产物是不是别的平台也能直接用。

结论是：

- 不能直接这么理解

当前成功的只是：

- 在当前机器
- 当前工具链
- 当前目标平台
- 当前 feature 集

下，Bazel 可以生成可执行文件。

从日志中能看到目标平台信息是 Linux：

- `CARGO_CFG_TARGET_OS=linux`
- `x86_64-unknown-linux-gnu`

所以当前生成的是：

- Linux 二进制

而不是：

- Windows 通用二进制
- macOS 通用二进制
- 单个跨平台产物

更准确地说，Bazel 给你的能力是：

- 用统一的 BUILD 规则，分别为 Linux、Windows、macOS 构建各自的产物

而不是：

- 一次构建，所有平台直接通用

## 8. 当前这个仓库里，迁移时你真正要重点验收的目标顺序

建议按下面顺序推进，而不是一开始就跑 `//...`。

### 第一步：先验证 CLI 主路径

```bash
bazel build //spider_cli:spider --repo_env=CARGO_BAZEL_REPIN=1 --verbose_failures
```

这是最小、最重要、最接近最终用户交付的路径。

这一步你已经成功了。

### 第二步：验证 worker

```bash
bazel build //spider_worker:spider_worker --repo_env=CARGO_BAZEL_REPIN=1 --verbose_failures
```

这是第二个核心二进制目标。只有它也过了，才能说明“主程序与 worker 两条主线都已迁入 Bazel”。

### 第三步：验证整仓

```bash
bazel build //... --repo_env=CARGO_BAZEL_REPIN=1 --keep_going --verbose_failures
```

这一步是全量扫尾，用来找：

- 边缘 feature
- 示例目标
- 测试目标
- 打包规则
- 没被主路径覆盖到的依赖缺口

### 第四步：验证发布打包

```bash
bazel build //:spider_release_archive --repo_env=CARGO_BAZEL_REPIN=1 --verbose_failures
```

这是迁移验收的最后一步，确认发布流程也能在 Bazel 下跑通。

## 9. 为什么很多命令都带 `CARGO_BAZEL_REPIN=1`

这个变量不是“每次都必须永久带着”，而是当前迁移阶段很有用。

它的作用可以理解为：

- 当 Bazel 侧对 Cargo 依赖的理解发生变化时
- 强制刷新 `crate_universe` 生成出来的外部依赖元数据

典型需要带它的场景包括：

- 你改了 [MODULE.bazel](/home/zhadainian/scientific_research/spider/MODULE.bazel)
- 你改了 Cargo 依赖
- 你改了 Bazel feature 配置
- 你改了 BUILD 文件里对 crate 的映射关系
- 你怀疑 `@crates` 图没有跟上当前仓库状态

在迁移阶段，这个变量很常见；等依赖图完全稳定后，可以视情况减少使用。

## 10. 这次迁移中已经落地的关键配置点

为了让你后面维护时知道去哪里看，这里把几个最关键的文件职责说清楚。

### 10.1 `MODULE.bazel`

这里负责：

- 引入 `rules_rust`
- 配置 Rust toolchain
- 配置 `crate_universe`
- 从 Cargo 元数据生成 `@crates`
- 对特殊 crate 做 annotation

这次迁移里，它还承担了一个很重要的兼容修复：

- 为 `aws-lc-sys` 注入 `-O0`

这是为了让其底层 `jitterentropy` C 文件通过编译。

### 10.2 `bazel/features.bzl`

这里不是装饰文件，而是当前迁移是否稳定的关键。

它负责定义：

- `spider` 在 Bazel 下启用哪些 feature
- `spider_agent` 启用哪些 feature
- `spider_cli` / `spider_worker` 对应什么 feature 集

之前很多编译爆炸，就是因为这里的 feature 开太宽。

现在的策略是：

- 只保留当前目标真正需要的 feature 闭包
- 不再用 Cargo workspace 全量大礼包思路硬搬到 Bazel

### 10.3 各 crate 的 `BUILD.bazel`

这些文件负责把每个 crate 暴露成 Bazel target，并且显式声明：

- `srcs`
- `crate_features`
- `deps`
- `proc_macro_deps`
- 测试目标和示例目标

这部分是 Bazel 视角下真正的“编译图描述”。

## 11. 当前 README 里你应该如何理解“迁移完成”

对这个仓库来说，“迁移完成”最好不要一刀切地说成已经 100% 完成，而应该分层描述。

更准确的结论应该是：

### 已完成

- Bazel 已经成为至少一条主路径的可用构建入口
- `//spider_cli:spider` 已经在 Linux 下成功构建
- `rules_rust + crate_universe + native crate` 的基础闭环已经成立

### 进行中

- `//spider_worker:spider_worker` 仍需验证
- `//...` 全量目标仍需验证
- 发布打包目标仍需验证

### 未验证

- Windows 原生 Bazel 构建
- macOS 原生 Bazel 构建
- 交叉编译流程

这样的描述才是技术上准确的。

## 12. 建议你后续怎么继续推进

如果你的目标不是“只证明 CLI 能编”，而是“真正把仓库迁到 Bazel”，那后面的推进顺序建议如下：

1. 固化当前 CLI 成功构建结果，不再随意扩大 feature 集。
2. 打通 `//spider_worker:spider_worker`。
3. 跑 `//...`，把 examples、tests、benches 的尾部问题收掉。
4. 打通 `//:spider_release_archive`。
5. 如果确实需要多平台，再分别验证 Windows 和 macOS，而不是假设 Linux 产物天然可跨平台。

## 13. 一句话总结

这个仓库迁移到 Bazel 后，你真正需要编译和验收的不是“一个命令”，而是四层内容：

- 主二进制：`spider_cli`、`spider_worker`
- 核心库：`spider`、`spider_agent` 等 workspace crate
- 外部 Rust 依赖：由 `crate_universe` 生成
- 原生依赖与打包流程：`aws-lc-sys`、`openssl-sys`、release archive 等

当前已经明确打通的是：

- Linux 下的 `//spider_cli:spider`

接下来真正要做的，不是重复证明 “Bazel 能不能用”，而是继续把：

- `spider_worker`
- 全仓目标
- 发布目标
- 额外平台

逐个验证完成。
