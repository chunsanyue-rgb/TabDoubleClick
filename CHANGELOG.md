# Changelog

本项目遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

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
