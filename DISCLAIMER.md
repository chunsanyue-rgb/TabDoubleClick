# 免责声明 / Disclaimer

> 最后更新：2026-11-05 · 适用于 TabDoubleClick（以下简称「本软件」）
> 本文件中英文具有同等效力；如有歧义，以中文版本为准。
> The Chinese and English versions are equally authoritative; in case of ambiguity, the Chinese version prevails.

---

## 1. 一句话版本

**这是一个免费、开源的个人项目。用之前请先明白：它能帮你关标签，也可能误关标签；作者不承担任何责任，出事别找我，但欢迎提 Issue。**

---

## 2. 性质说明

1. 本软件是**个人业余时间开发的开源项目**，不是商业产品，没有公司、团队或商业实体为其提供支持、SLA 或售后。
2. 本软件按 **MIT 许可证** 开源（见 [LICENSE](LICENSE) / [中文译文](LICENSE.zh-CN.md)），以**「现状」（AS IS）**提供，**不附带任何明示或默示的担保**，包括但不限于适销性、特定用途适用性、无缺陷和不侵权的担保。
3. 本项目**与 Google、Apple、Microsoft、Mozilla、Citro Labs（ego lite）及其关联公司没有任何隶属、合作、赞助或背书关系**。文中出现的产品名称、图标、商标均归其各自所有者所有，仅用于描述兼容性（合理使用 / nominative fair use）。
4. 本项目**不是**任何浏览器的官方功能，也不代表任何浏览器的官方立场。

## 3. 使用风险自负

使用本软件即表示你理解并接受以下风险：

1. **可能误关标签页**：本软件通过「鼠标双击位置 + 窗口几何区域」判断是否点在标签栏上，属于**启发式判断**，不是浏览器内部事件。窗口缩放、标签栏样式变化、浏览器更新、多显示器、外接屏、全屏模式、系统缩放（HiDPI）、辅助功能缩放等情况，都可能导致判断偏移，从而**关闭你并不想关闭的标签页**。
2. **可能丢失未保存的内容**：被误关的标签内如果有未提交的表单、未保存的编辑内容，可能无法恢复。请在重要操作前自行确认或先保存。
3. **可能与其他软件冲突**：本软件会全局监听鼠标左键事件并模拟 `⌘W`。如果你使用的其他工具（窗口管理器、宏工具、远程控制软件、游戏/绘图软件等）也监听或拦截鼠标事件，可能出现互相干扰、重复触发或都不触发。
4. **可能随系统/浏览器更新失效**：macOS 大版本升级、浏览器界面改版后，标签栏坐标参数可能需要重新校准（菜单栏 →「校准当前浏览器的标签栏…」）。本软件**不保证**在任何版本上持续可用。
5. **Apple 私有机制的不确定性**：本软件依赖 macOS 的辅助功能（Accessibility）与事件模拟能力，这些机制由 Apple 单方面控制，随时可能变更或收紧，且不保证对第三方应用开放。

## 4. 权限与隐私

1. 本软件需要**「辅助功能」**权限，仅用于两件事：读取前台窗口的位置与尺寸、发送 `⌘W` 按键。
2. 本软件**不联网**、**不上报遥测**、**不需要账号**、**不读取网页内容**、**不记录键盘输入**、**不截屏**。
3. 运行日志（`~/Library/Logs/TabDoubleClick.log`）、配置（`~/Library/Application Support/TabDoubleClick/config.json`）与统计（`stats.json`）**全部仅存于本机**，不会上传到任何服务器。
4. 上述文件不会随卸载自动清除，如需彻底删除请手动移除对应目录。

## 5. 合规使用

1. 请在**你有权操作的设备**上使用本软件。**严禁**将其用于未经他人明确同意的设备，包括但不限于隐蔽安装、监控他人、远程操控他人电脑等用途。
2. 使用者应自行遵守所在国家/地区的法律法规，以及其雇主、学校或组织的信息安全规定。因违反上述规定产生的一切后果由使用者自行承担。
3. 本软件不得用于任何违法用途，也不得用于规避法律、监管或平台规则。

## 6. 责任限制

在适用法律允许的最大范围内：

1. 作者（chunsanyue）及任何贡献者**不对**因使用或无法使用本软件而产生的任何**直接、间接、偶然、特殊、惩罚性或后果性损害**承担责任，包括但不限于：数据丢失、工作中断、利润损失、设备损坏、第三方索赔。
2. 无论损害基于合同、侵权、严格责任还是其他理论，也无论作者是否已被告知此类损害的可能性，上述限制均适用。
3. 若你所在司法辖区不允许排除默示担保或限制附带损害责任，上述部分限制可能不适用于你，此时以法律强制规定为准。
4. 你**唯一且排他**的救济方式是：停止使用并删除本软件。

## 7. 第三方与商标

- Chrome、Chrome Canary、Chromium、Google 是 Google LLC 的商标。
- Safari、macOS、Apple 是 Apple Inc. 的商标。
- Edge、Windows 是 Microsoft Corporation 的商标。
- Firefox 是 Mozilla Foundation 的商标。
- ego lite 是 Citro Labs 的商标。
- Arc、Brave、Vivaldi、Opera、Orion、Zen、DuckDuckGo、Thorium、Sidekick 等名称归其各自所有者所有。

本项目未获上述任何主体授权、赞助或背书；相关名称仅用于说明「可以与哪些浏览器配合使用」。

## 8. 免责声明的变更

作者可随时更新本免责声明，更新后立即生效（见仓库提交历史）。若你在更新后继续使用本软件，视为接受更新后的条款。**若你不同意本声明的任何内容，请立即停止使用并删除本软件。**

---

## English Summary

TabDoubleClick is a **free, open-source hobby project** provided **"AS IS", without warranty of any kind**, under the [MIT License](LICENSE).

- **Not affiliated** with Google, Apple, Microsoft, Mozilla, Citro Labs, or any browser vendor. All product names and trademarks belong to their respective owners and are used only to describe compatibility.
- **Use at your own risk.** Tab detection is heuristic (mouse position + window geometry), so the app **may close a tab you did not intend to close**, and unsaved content in that tab may be lost. Behaviour may break after macOS or browser updates.
- **Privacy:** the app requires Accessibility permission solely to read the frontmost window frame and send `⌘W`. It does **not** connect to the network, does **not** collect telemetry, does **not** read page content, and logs stay **local only**.
- **Lawful use only:** install it only on devices you are authorised to control. Using it on someone else's machine without consent (e.g. covert monitoring or remote control) is strictly prohibited.
- **Limitation of liability:** to the maximum extent permitted by law, the author and contributors are **not liable** for any direct, indirect, incidental, special, or consequential damages — including data loss, lost work, or third-party claims — arising from the use of, or inability to use, this software. Your sole remedy is to stop using and delete the software.
- If you do not agree with any part of this disclaimer, **stop using the software immediately** and delete it.

Questions or corrections: please open an [issue](https://github.com/chunsanyue-rgb/TabDoubleClick/issues).

---

© 2026 [chunsanyue](https://github.com/chunsanyue-rgb) · [MIT License](LICENSE)
