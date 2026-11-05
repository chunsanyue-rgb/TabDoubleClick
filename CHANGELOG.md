# Changelog

本项目遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

## [未发布]

### 文档

- 署名作者 **chunsanyue**（[@chunsanyue-rgb](https://github.com/chunsanyue-rgb)）：README 新增「作者」章节，头部徽章与页脚同步标注
- **新增中文版许可证** `LICENSE.zh-CN.md`（MIT 中文参考译文 + 大白话说明），`LICENSE` 保持英文原文以通过 GitHub 的协议识别
- `Info.plist` 新增 `NSHumanReadableCopyright`，安装包的「显示简介」中可见版权信息

## [1.1.0] - 2026-11-05

### 新增

- **一键校准标签栏**：菜单点「校准当前浏览器的标签栏…」，在标签栏上双击一次，自动测出该浏览器的标签栏位置并写入配置。任意浏览器、任意标签栏布局（如 Safari 的独立/紧凑模式）都能一次对准，不再需要看日志手算像素
- **未适配的浏览器也能校准**：校准会为当前前台浏览器自动生成新配置项（Thorium、Sidekick、360、QQ 等）
- **关闭统计**：菜单显示「今日已关闭 N 个（累计 M）」，数据只存本地 `stats.json`
- **26 款浏览器开箱即用**：新增 Arc、Opera / Opera GX、Chromium、Chrome Beta/Dev、Edge Beta/Dev/Canary、Brave Beta/Nightly、Opera Beta、Firefox Developer/Nightly、Safari Technology Preview、Orion、Zen、DuckDuckGo
- **全局设置 `_settings`**：`cooldown`（关闭冷却时间）与 `sound`（关闭提示音）可配置
- **日志自动轮转**：超过 512 KB 自动转存为 `.log.1`，长期常驻不再无限增长
- **Universal 二进制**：CI 产出 arm64 + x86_64 通用包，Intel Mac 免编译直接用
- 菜单增强：显示当前前台浏览器的适配状态与标签栏参数、「查看日志…」入口
- 「参数不准怎么办」排障路径更新为：先校准，再手调

### 变更

- Safari 默认参数改为 `tabHeight 42 / leftInset 78`（独立标签栏布局请用一键校准，一次到位）
- 已有用户的 `config.json` 完全兼容，升级后新增浏览器自动并入，无需改动

### 已知限制

- 双击「+」新建标签按钮时，会先建一个标签再被关闭
- Chrome 中双击标签栏空白处会同时触发"新建标签"

## [1.0.0] - 2026-11-05

首个公开版本。

### 新增

- 双击浏览器标签栏关闭标签，通过合成 `⌘W` 实现
- 多浏览器自动适配：ego lite、Chrome、Chrome Canary、Edge、Brave、Vivaldi、Firefox、Safari
- 按浏览器区分标签栏几何参数（高度 / 左侧避让 / 是否允许全屏）
- 使用 `AXFullScreen` 属性判断全屏，多显示器坐标换算正确
- 光标所在窗口判定，多窗口时不误判
- 配置外置到 `~/Library/Application Support/TabDoubleClick/config.json`，支持热重载
- 菜单栏控制中心：启用/停用、权限状态、打开辅助功能设置、重新检测权限、重载配置、打开配置、退出
- 权限状态 2 秒轮询，授权后无需重启
- 诊断日志：记录每次双击的坐标、窗口范围、命中结果

### 已知限制

- 双击「+」新建标签按钮时，会先建一个标签再被关闭
- Chrome 中双击标签栏空白处会同时触发"新建标签"
- 目前仅 Release 提供 Apple 芯片版本，Intel Mac 需源码编译
