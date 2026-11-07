# 开发贡献指南 / Contributing Guide

感谢你对 Slive 的关注！欢迎各种形式的贡献，无论是修复 bug、添加新功能、改进文档还是提出建议。
## 贡献须知
- 因为一些原因，**dev** 作为Github Flow开发流程的主干
- **master** 分支发版时 通过 merge squash dev，会在停更时删除dev分支并脱敏
- 所以仓库的贡献者包括贡献代码统计都是不存在的

## 🎯 贡献类型

欢迎以下类型的贡献：

### 🐛 修复 Bug
- 在 Issues 中查找标记为 `bug` 的问题
- 如果发现新的 bug，请先[创建 Issue](https://github.com/SlotSun/dart_simple_live/issues/new/choose) 描述问题

### ✨ 添加新功能
- 查找标记为 `enhancement`的 Issue
- 对于较大的功能，建议先创建 Issue 讨论设计方案

### 📖 改进文档
- 修复文档中的错误或不清晰的地方
- 添加使用示例和最佳实践

### 🧪 添加测试
- 为现有功能添加单元测试
- 改进测试覆盖率
- 添加集成测试

### 🎨 UI/UX 改进
- 优化界面交互体验
- 修复界面样式问题
- 提升易用性

## 🚀 快速开始

### 前置要求

确保你的环境中已安装： 

- **Flutter 3.47.8^**
- **Rust 1.28^**
- **Visual Studio**

### 安装 FVM

```bash
# macOS/Linux
curl -sL https://install.fvm.sh | bash

# Windows
choco install fvm
```

### 安装 Flutter

```bash
# windows
fvm version
fvm list
fvm install 3.38.6
```

**Linux**
[详见官网教程](https://docs.flutter.dev/install/manual)

### 克隆仓库

```bash
git clone https://github.com/SlotSun/dart_simple_live.git
cd dart_simple_live/simple_live_app
```

## 🏷️ 认领任务

### 查找任务

1. 浏览 [Issues 页面](https://github.com/SlotSun/dart_simple_live/issues)
2. 查找带有以下标签的 Issue：
    - `help wanted` - 需要社区帮助的任务
    - `bug` - Bug 修复
    - `enhancement` - 功能增强

### 认领流程

在你想要处理的 Issue 下评论：
```
/assign me
```

或者：
```
我可以解决此问题
```


## 💻 本地开发

### 1. 安装依赖

**Flutter依赖**：
```bash
fvm use 3.38.6
# 安装Flutter_rust_bridge
cargo install flutter_rust_bridge_codegen
flutter pub get
```

### 2. 启动开发服务器

**启动APP**（支持热重载）：
```bash
flutter run
```

### 3. 构建项目

**安装 fastforge**
```bash
git clone https://github.com/SlotSun/fastforge.git
cd fastforge
dart pub global activate melos
melos run activate
```
**Windows-安装 innosetup**
```bash
# 打包 windows
choco install innosetup
```
**构建APP**：
```bash
# bash in simple_live_app
cd simple_live_app
# 打包 windows
fastforge package --platform windows --targets msix,zip,exe --skip-clean
# Linux
fastforge package --platform linux --targets deb,zip --skip-clean
# Android-need key
flutter build apk --release --split-per-abi
```

## 📁 代码结构

### 项目目录速览
- `simple_live_core` 项目核心库，实现获取各个网站的信息及弹幕。
- `simple_live_console` 基于simple_live_core的控制台程序。
- `simple_live_app` 基于核心库实现的Flutter APP客户端。
- `simple_live_tv_app` 基于核心库实现的Flutter Android TV客户端。

### 技术栈

**Flutter**：
- GetX(状态管理、路由)
- Hive(持久化)
- Dio(实时通信)

## 📝 提交规范

我们遵循 [Conventional Commits](https://www.conventionalcommits.org/) 规范：

### Commit 格式

```
<类型>(<范围>): <简短描述>

[可选的详细描述]

[可选的脚注]
```

### 类型 (Type)

- `feat`: 新功能
- `fix`: Bug 修复
- `docs`: 文档变更
- `style`: 代码格式调整（不影响功能）
- `refactor`: 重构（既不是新功能也不是 bug 修复）
- `perf`: 性能优化
- `test`: 添加或修改测试
- `chore`: 辅助工具的变动
- `ci`: 构建过程的变动

### 范围 (Scope)

可选，指明改动的模块：
- `platfrom` - 直播平台
- `Windows/Linux/Android` - 用户平台
- `ui` - 用户界面
- `ci` - 构建系统
- `docs` - 文档

### 示例

```bash
feat(api): add layered agent support
```

## 🔍 Pull Request 要求
### PR 流程
```bash
git clone https://github.com/SlotSun/dart_simple_live.git
# 基于dev分支创建 Type-Scope的分支
git checkout -b fix-xx origin/dev
```
**完成测试后，向主仓库的dev分支提交pr**
### 提交前检查清单

- [ ] 代码通过格式检查
- [ ] 对于新功能，添加了相应的文档说明
- [ ] 对于 UI 改动，提供了截图或录屏
- [ ] Commit 信息遵循规范格式
- [ ] PR 描述清晰说明了改动内容和原因

### PR 标题格式

PR 标题应该简洁明了，建议格式：

```
<类型>: <简短描述>
```

例如：
- `feat: add WiFi device pairing support`
- `fix: resolve video stream crash on device disconnect`
- `docs: improve quick start guide`

### PR 描述模板

提交 PR 时，请使用以下模板：

```markdown
## 改动说明

<!-- 简要描述这个 PR 做了什么 -->

## 相关 Issue

<!-- 关联的 Issue 编号，如 Closes #123 -->

## 改动类型

- [ ] Bug 修复
- [ ] 新功能
- [ ] 文档更新
- [ ] 代码重构
- [ ] 性能优化
- [ ] 其他（请说明）

## 测试说明

<!-- 如何测试这些改动？ -->

## 截图/录屏

<!-- 对于 UI 改动，请提供截图或录屏 -->

## 其他说明

<!-- 其他需要说明的内容 -->
```

### Code Review

提交 PR 后：
1. 维护者会审查你的代码
2. 可能会提出改进建议
3. 请及时回复评论并根据反馈调整代码
4. 所有讨论解决后，PR 会被合并

## 🤝 行为准则

### 我们的承诺

为了营造一个开放和友好的环境，我们承诺：

- 尊重不同的观点和经验
- 优雅地接受建设性批评
- 关注对社区最有利的事情
- 对其他社区成员表示同理心

### 不可接受的行为

以下行为被视为不可接受：

- 使用性别化的语言或图像，以及不受欢迎的性关注
- 骚扰性评论、侮辱性/贬损性评论，以及人身或政治攻击
- 公开或私下骚扰
- 未经明确许可，发布他人的私人信息
- 其他在专业环境中可能被认为不适当的行为

## 🎉 感谢贡献

感谢你花时间为 Slive 做出贡献！你的努力让这个项目变得更好。

有任何问题？欢迎：
- 在 [Issues](https://github.com/SlotSun/dart_simple_live/issues) 提问

---