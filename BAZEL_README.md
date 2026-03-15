# Spider Bazel 构建指南

本项目已从 Cargo 构建系统迁移到 Bazel，支持多语言构建（Rust + Go + Node.js）。

## 目录

- [环境要求](#环境要求)
- [快速开始](#快速开始)
- [项目结构](#项目结构)
- [构建命令](#构建命令)
- [Feature Flags](#feature-flags)
- [多语言支持](#多语言支持)
- [与 Cargo 共存](#与-cargo-共存)
- [文件说明](#文件说明)

## 环境要求

- Bazel 7.0+ 或 Bazelisk
- Rust 工具链（stable）
- Go 工具链（可选，用于 Go 基准测试）
- Node.js（可选，用于 Node.js 基准测试）

## 快速开始

```bash
# 构建核心库
bazel build //spider:spider

# 构建命令行工具
bazel build //spider_cli:spider

# 构建 Worker 服务
bazel build //spider_worker:spider_worker

# 构建所有目标
bazel build //...
```

## 项目结构

```
spider/
├── WORKSPACE              # Bazel 工作区配置
├── BUILD.bazel            # 根构建文件（Feature Flags 定义）
├── .bazelrc               # Bazel 配置
├── .bazelignore           # Bazel 忽略文件
├── crates.bzl             # crate_universe 依赖配置
├── features.bzl           # Feature Flag 文档和辅助函数
│
├── spider/                # 核心库 - 爬虫引擎
│   └── BUILD.bazel
├── spider_cli/            # CLI 工具
│   └── BUILD.bazel
├── spider_worker/         # Worker/Proxy 服务
│   └── BUILD.bazel
├── spider_utils/          # 工具库
│   └── BUILD.bazel
├── spider_agent/          # Agent 库
│   └── BUILD.bazel
├── spider_agent_types/    # Agent 类型定义
│   └── BUILD.bazel
├── spider_agent_html/     # HTML 处理
│   └── BUILD.bazel
├── benches/               # 基准测试
│   └── BUILD.bazel
└── examples/              # 示例代码
    └── BUILD.bazel
```

### Crate 依赖关系

```
spider_agent_types  ←────────────────────────────────┐
     ↓                                               │
spider_agent_html ──→ spider_agent ──→ spider ──────┘
                           ↓              ↓
                     spider_cli    spider_worker
```

## 构建命令

### 基础构建

```bash
# 构建核心库
bazel build //spider:spider

# 构建命令行工具
bazel build //spider_cli:spider

# 构建 Worker 服务
bazel build //spider_worker:spider_worker

# 构建所有库
bazel build //spider/... //spider_agent/... //spider_utils/...
```

### 启用特性

```bash
# 启用 Chrome 浏览器自动化
bazel build //spider:spider --config=chrome

# 启用 OpenAI 集成
bazel build //spider:spider --config=openai

# 启用 Gemini 集成
bazel build //spider:spider --config=gemini

# 启用 WebDriver 支持
bazel build //spider:spider --config=webdriver

# 启用缓存
bazel build //spider:spider --config=cache

# 启用 Smart 模式
bazel build //spider:spider --config=smart

# 组合多个特性
bazel build //spider:spider --config=chrome --config=openai
```

### 发布构建

```bash
# 优化构建（相当于 cargo build --release）
bazel build //spider_cli:spider --config=release

# 完全 LTO 优化
bazel build //spider_cli:spider --config=release --features=full_lto
```

### 平台特定构建

```bash
# Linux 特定
bazel build //spider:spider --config=linux

# macOS 特定
bazel build //spider:spider --config=macos

# Windows 特定
bazel build //spider:spider --config=windows
```

## Feature Flags

本项目支持 40+ 个 Feature Flags，以下是主要特性：

### 核心特性

| Flag | 默认值 | 说明 |
|------|--------|------|
| `sync` | true | 启用同步爬取 API |
| `serde` | true | 启用序列化支持 |
| `io_uring` | true | 启用 io_uring（仅 Linux） |
| `encoding` | false | 启用字符编码检测 |
| `time` | false | 启用时间跟踪 |
| `cookies` | false | 启用 Cookie 支持 |

### 浏览器自动化

| Flag | 默认值 | 说明 |
|------|--------|------|
| `chrome` | false | 启用 Chrome 浏览器自动化 |
| `chrome_headed` | false | 有头模式运行 Chrome |
| `chrome_stealth` | false | Chrome 隐身模式 |
| `chrome_screenshot` | false | Chrome 截图功能 |
| `chrome_intercept` | false | Chrome 请求拦截 |
| `smart` | false | 智能爬取模式 |
| `webdriver` | false | WebDriver 支持 |

### LLM 集成

| Flag | 默认值 | 说明 |
|------|--------|------|
| `openai` | false | OpenAI 集成 |
| `gemini` | false | Gemini 集成 |

### 缓存

| Flag | 默认值 | 说明 |
|------|--------|------|
| `cache` | false | HTTP 请求缓存 |
| `cache_mem` | false | 内存缓存 |
| `cache_openai` | false | OpenAI 响应缓存 |

### Agent 特性

| Flag | 默认值 | 说明 |
|------|--------|------|
| `agent` | false | Agent 集成 |
| `agent_openai` | false | Agent + OpenAI |
| `agent_chrome` | false | Agent + Chrome |
| `agent_webdriver` | false | Agent + WebDriver |
| `agent_skills` | false | Agent 技能 |
| `agent_full` | false | 完整 Agent 功能集 |

### 其他特性

| Flag | 默认值 | 说明 |
|------|--------|------|
| `sitemap` | false | Sitemap 解析 |
| `cron` | false | 定时任务 |
| `tracing` | false | Tracing 支持 |
| `firewall` | false | 防火墙检测 |
| `spider_cloud` | false | Spider Cloud 集成 |

## 多语言支持

### Go 基准测试

```bash
# 构建 Go 版本的爬虫基准测试
bazel build //benches:gospider

# 运行 Go 基准测试
./bazel-bin/benches/gospider https://example.com
```

### Rust 基准测试

```bash
# 构建爬取基准测试
bazel build //benches:crawl_bench

# 构建核心基准测试
bazel build //benches:core_bench
```

### Node.js 支持

Node.js 支持已预留，需要配置 `rules_nodejs` 或 `rules_js`。取消 `benches/BUILD.bazel` 中的注释即可启用。

## 与 Cargo 共存

Bazel 构建系统与 Cargo 可以共存，支持渐进式迁移：

```bash
# 使用 Cargo 构建
cargo build

# 使用 Bazel 构建
bazel build //...

# 两者可以同时使用
cargo build && bazel build //spider_cli:spider
```

### 依赖管理

- **Cargo**: `Cargo.toml` 和 `Cargo.lock` 仍然是依赖声明的源
- **Bazel**: `crate_universe` 从 `Cargo.lock` 生成 Bazel 依赖

当更新依赖时：

```bash
# 1. 更新 Cargo.toml
cargo add <package>

# 2. 更新 Cargo.lock
cargo update

# 3. Bazel 会自动使用新的依赖
bazel build //spider:spider
```

## 文件说明

### WORKSPACE

工作区配置文件，包含：
- `rules_rust` - Rust 规则
- `crate_universe` - Cargo 依赖转换
- `rules_go` - Go 规则
- `bazel_gazelle` - Go BUILD 文件生成
- `platforms` - 平台定义
- `bazel_skylib` - 通用工具

### BUILD.bazel

各目录的构建文件，定义：
- `rust_library` - Rust 库目标
- `rust_binary` - Rust 二进制目标
- `go_binary` - Go 二进制目标
- `select()` - 条件编译

### crates.bzl

crate_universe 配置，从 Cargo 依赖生成 Bazel 目标。

### features.bzl

Feature Flag 文档，包含：
- 所有特性的说明
- 依赖关系
- 辅助函数

### .bazelrc

Bazel 配置文件，包含：
- 构建选项
- Feature Flag 映射
- 发布构建配置

## 常见问题

### Q: 如何查看可用的构建目标？

```bash
bazel query //...
```

### Q: 如何查看特定目标的依赖？

```bash
bazel query "deps(//spider:spider)"
```

### Q: 如何清理构建缓存？

```bash
bazel clean
```

### Q: 如何查看构建详情？

```bash
bazel build //spider:spider --verbose_failures
```

### Q: io_uring 只在 Linux 上可用，如何禁用？

```bash
bazel build //spider:spider --//spider:io_uring=false
```

## 验证步骤

```bash
# 1. 基础构建验证
bazel build //spider:spider
bazel build //spider_cli:spider
bazel build //spider_worker:spider_worker

# 2. Feature flags 验证
bazel build //spider:spider --config=chrome
bazel build //spider:spider --config=openai

# 3. 发布构建验证
bazel build //spider_cli:spider --config=release

# 4. 与 Cargo 输出对比
cargo build --release
bazel build //spider_cli:spider --config=release
```

## 联系方式

- 项目地址: https://github.com/spider-rs/spider
- 问题反馈: https://github.com/spider-rs/spider/issues