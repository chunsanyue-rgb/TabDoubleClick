import Cocoa
import ApplicationServices

// ===== 各浏览器标签栏适配参数 =====
struct BrowserProfile {
    let name: String          // 显示名
    let tabHeight: CGFloat    // 标签栏高度（从窗口顶部往下多少像素）
    let leftInset: CGFloat    // 左侧避让（红绿灯按钮）
    let allowFullscreen: Bool // 全屏时是否仍可双击关标签
}

let defaultProfiles: [String: BrowserProfile] = [
    "com.citrolabs.ego.lite":       BrowserProfile(name: "ego lite", tabHeight: 40, leftInset: 80, allowFullscreen: true),
    "com.google.Chrome":            BrowserProfile(name: "Chrome",   tabHeight: 40, leftInset: 80, allowFullscreen: true),
    "com.google.Chrome.canary":     BrowserProfile(name: "Chrome Canary", tabHeight: 40, leftInset: 80, allowFullscreen: true),
    "com.microsoft.edgemac":        BrowserProfile(name: "Edge",     tabHeight: 40, leftInset: 80, allowFullscreen: true),
    "com.brave.Browser":            BrowserProfile(name: "Brave",    tabHeight: 40, leftInset: 80, allowFullscreen: true),
    "com.vivaldi.Vivaldi":          BrowserProfile(name: "Vivaldi",  tabHeight: 40, leftInset: 78, allowFullscreen: true),
    "org.mozilla.firefox":          BrowserProfile(name: "Firefox",  tabHeight: 42, leftInset: 78, allowFullscreen: true),
    "com.apple.Safari":             BrowserProfile(name: "Safari",   tabHeight: 38, leftInset: 78, allowFullscreen: false),
]

// ===== 可调参数：改动只需编辑 config.json 并点菜单"重新加载配置"，无需重编译、无需重新授权 =====
let supportDir = NSString(string: "~/Library/Application Support/TabDoubleClick").expandingTildeInPath
let configPath = (supportDir as NSString).appendingPathComponent("config.json")

var profiles: [String: BrowserProfile] = defaultProfiles

func writeDefaultConfigIfNeeded() {
    try? FileManager.default.createDirectory(atPath: supportDir, withIntermediateDirectories: true)
    guard !FileManager.default.fileExists(atPath: configPath) else { return }
    var obj: [String: Any] = [:]
    for (bid, p) in defaultProfiles {
        obj[bid] = ["name": p.name, "tabHeight": p.tabHeight, "leftInset": p.leftInset, "allowFullscreen": p.allowFullscreen]
    }
    if let data = try? JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .sortedKeys]) {
        try? data.write(to: URL(fileURLWithPath: configPath))
    }
}

func loadConfig() {
    var merged = defaultProfiles
    guard let data = FileManager.default.contents(atPath: configPath),
          let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
        profiles = merged
        logLine("配置读取失败，使用内置默认值")
        return
    }
    for (bid, raw) in obj {
        guard let d = raw as? [String: Any] else { continue }
        let base = defaultProfiles[bid]
        let name = (d["name"] as? String) ?? base?.name ?? bid
        let h = (d["tabHeight"] as? NSNumber)?.doubleValue ?? Double(base?.tabHeight ?? 40)
        let l = (d["leftInset"] as? NSNumber)?.doubleValue ?? Double(base?.leftInset ?? 80)
        let f = (d["allowFullscreen"] as? Bool) ?? base?.allowFullscreen ?? true
        merged[bid] = BrowserProfile(name: name, tabHeight: CGFloat(h), leftInset: CGFloat(l), allowFullscreen: f)
    }
    profiles = merged
    logLine("配置已加载：\(profiles.count) 个浏览器配置")
}

let leftInsetFullscreen: CGFloat = 6
let rightInset: CGFloat = 12
let cooldown: TimeInterval = 0.4

let logPath = NSString(string: "~/Library/Logs/TabDoubleClick.log").expandingTildeInPath

func logLine(_ s: String) {
    let ts = ISO8601DateFormatter().string(from: Date())
    let line = "[\(ts)] \(s)\n"
    if let h = FileHandle(forWritingAtPath: logPath) {
        h.seekToEndOfFile()
        h.write(line.data(using: .utf8)!)
        h.closeFile()
    } else {
        try? line.write(toFile: logPath, atomically: true, encoding: .utf8)
    }
}

struct WinInfo {
    let frame: CGRect
    let fullscreen: Bool
}

/// 取目标 App 所有窗口的 frame（AX 左上原点坐标系）与全屏状态
func axWindows(pid: pid_t) -> [WinInfo] {
    let app = AXUIElementCreateApplication(pid)
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &value) == .success,
          let windows = value as? [AXUIElement] else { return [] }

    var result: [WinInfo] = []
    for win in windows {
        var posRef: CFTypeRef?
        var sizeRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(win, kAXPositionAttribute as CFString, &posRef) == .success,
              AXUIElementCopyAttributeValue(win, kAXSizeAttribute as CFString, &sizeRef) == .success,
              let posVal = posRef, let sizeVal = sizeRef else { continue }
        var point = CGPoint.zero
        var size = CGSize.zero
        guard AXValueGetValue(posVal as! AXValue, .cgPoint, &point),
              AXValueGetValue(sizeVal as! AXValue, .cgSize, &size) else { continue }

        var fsRef: CFTypeRef?
        var isFull = false
        if AXUIElementCopyAttributeValue(win, "AXFullScreen" as CFString, &fsRef) == .success,
           let b = fsRef as? Bool {
            isFull = b
        }
        result.append(WinInfo(frame: CGRect(origin: point, size: size), fullscreen: isFull))
    }
    return result
}

func sendCmdW() {
    let src = CGEventSource(stateID: .hidSystemState)
    let keyW: CGKeyCode = 13
    guard let down = CGEvent(keyboardEventSource: src, virtualKey: keyW, keyDown: true),
          let up = CGEvent(keyboardEventSource: src, virtualKey: keyW, keyDown: false) else { return }
    down.flags = .maskCommand
    up.flags = .maskCommand
    down.post(tap: .cgSessionEventTap)
    up.post(tap: .cgSessionEventTap)
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var monitor: Any?
    var enabled = true
    var lastClose = Date.distantPast
    var menuItemEnable: NSMenuItem?
    var menuItemStatus: NSMenuItem?
    var permissionTimer: Timer?
    var lastTrusted: Bool?

    func applicationDidFinishLaunching(_ notification: Notification) {
        writeDefaultConfigIfNeeded()
        loadConfig()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.title = "⇥"
        statusItem?.button?.toolTip = "双击标签栏关闭标签"

        let menu = NSMenu()
        let item = NSMenuItem(title: "已启用", action: #selector(toggleEnabled), keyEquivalent: "")
        menu.addItem(item)
        menuItemEnable = item

        let status = NSMenuItem(title: "权限：检测中…", action: nil, keyEquivalent: "")
        status.isEnabled = false
        menu.addItem(status)
        menuItemStatus = status

        let scope = NSMenuItem(title: "生效：ego lite / Chrome / Edge / Brave / Vivaldi / Firefox / Safari", action: nil, keyEquivalent: "")
        scope.isEnabled = false
        menu.addItem(scope)

        menu.addItem(NSMenuItem(title: "打开辅助功能设置…", action: #selector(openAccessibility), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "重新检测权限", action: #selector(recheck), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "重新加载配置", action: #selector(reloadConfig), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "打开配置文件…", action: #selector(openConfig), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "退出", action: #selector(quit), keyEquivalent: "q"))
        statusItem?.menu = menu

        let prompt = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(prompt)

        refreshPermission(registerIfNeeded: true)

        permissionTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.refreshPermission(registerIfNeeded: true)
        }
    }

    func refreshPermission(registerIfNeeded: Bool) {
        let trusted = AXIsProcessTrusted()
        if lastTrusted != trusted {
            logLine("辅助功能权限状态: \(trusted)")
            lastTrusted = trusted
        }
        menuItemStatus?.title = trusted ? "权限：已授权 ✓" : "权限：未授权（请到 系统设置 → 隐私与安全性 → 辅助功能 打开）"
        if trusted && monitor == nil && registerIfNeeded {
            monitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown]) { [weak self] event in
                self?.handle(event)
            }
            logLine(monitor == nil ? "监听注册失败" : "全局鼠标监听已就绪")
        }
    }

    func handle(_ event: NSEvent) {
        guard enabled, event.clickCount == 2 else { return }
        guard Date().timeIntervalSince(lastClose) > cooldown else { return }
        guard let front = NSWorkspace.shared.frontmostApplication,
              let bid = front.bundleIdentifier,
              let profile = profiles[bid] else { return }

        // CGEvent 全局坐标即为 AX 坐标系（主屏左上原点），多显示器也准确
        guard let cg = CGEvent(source: nil)?.location else { return }
        let point = CGPoint(x: cg.x, y: cg.y)

        let windows = axWindows(pid: front.processIdentifier)
        guard let win = windows.first(where: { $0.frame.contains(point) }) ?? windows.first else { return }

        if win.fullscreen && !profile.allowFullscreen {
            logLine("\(profile.name)：全屏模式已跳过（标签栏会隐藏，避免误关）")
            return
        }

        let inset = win.fullscreen ? leftInsetFullscreen : profile.leftInset
        let inX = point.x >= win.frame.minX + inset && point.x <= win.frame.maxX - rightInset
        let inY = point.y >= win.frame.minY && point.y <= win.frame.minY + profile.tabHeight

        logLine("\(profile.name) 双击 点=(\(Int(point.x)),\(Int(point.y))) 窗口=(\(Int(win.frame.minX)),\(Int(win.frame.minY)),\(Int(win.frame.width))x\(Int(win.frame.height))) 全屏=\(win.fullscreen) 命中=\(inX && inY)")

        guard inX && inY else { return }

        lastClose = Date()
        sendCmdW()
        logLine("→ 已发送 ⌘W（\(profile.name)）")
    }

    @objc func toggleEnabled() {
        enabled.toggle()
        menuItemEnable?.title = enabled ? "已启用" : "已停用"
        logLine("切换启用状态: \(enabled)")
    }

    @objc func openAccessibility() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    @objc func recheck() {
        refreshPermission(registerIfNeeded: true)
        logLine("手动重新检测权限：\(AXIsProcessTrusted())")
    }

    @objc func reloadConfig() {
        loadConfig()
    }

    @objc func openConfig() {
        writeDefaultConfigIfNeeded()
        NSWorkspace.shared.open(URL(fileURLWithPath: configPath))
    }

    @objc func quit() { NSApp.terminate(nil) }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
