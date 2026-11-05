import Cocoa
import ApplicationServices

// ============================================================
// TabDoubleClick — 双击浏览器标签栏关闭标签
// 原生 macOS 菜单栏工具 · MIT License
// https://github.com/chunsanyue-rgb/TabDoubleClick
// ============================================================

let appVersion = "1.1.0"

// ===== 各浏览器标签栏适配参数 =====
// tabHeight      : 从窗口顶部往下多少像素算"标签栏"
// leftInset      : 左侧避让（红绿灯按钮宽度）
// allowFullscreen: 全屏时是否仍可双击（全屏会把标签栏藏起来的浏览器应设 false）
struct BrowserProfile {
    var name: String
    var tabHeight: CGFloat
    var leftInset: CGFloat
    var allowFullscreen: Bool
}

let defaultProfiles: [String: BrowserProfile] = [
    // Chromium 系
    "com.citrolabs.ego.lite":        BrowserProfile(name: "ego lite",     tabHeight: 40, leftInset: 80, allowFullscreen: true),
    "com.google.Chrome":             BrowserProfile(name: "Chrome",       tabHeight: 40, leftInset: 80, allowFullscreen: true),
    "com.google.Chrome.beta":        BrowserProfile(name: "Chrome Beta",  tabHeight: 40, leftInset: 80, allowFullscreen: true),
    "com.google.Chrome.dev":         BrowserProfile(name: "Chrome Dev",   tabHeight: 40, leftInset: 80, allowFullscreen: true),
    "com.google.Chrome.canary":      BrowserProfile(name: "Chrome Canary",tabHeight: 40, leftInset: 80, allowFullscreen: true),
    "org.chromium.Chromium":         BrowserProfile(name: "Chromium",     tabHeight: 40, leftInset: 80, allowFullscreen: true),
    "com.microsoft.edgemac":         BrowserProfile(name: "Edge",         tabHeight: 40, leftInset: 80, allowFullscreen: true),
    "com.microsoft.edgemac.Beta":    BrowserProfile(name: "Edge Beta",    tabHeight: 40, leftInset: 80, allowFullscreen: true),
    "com.microsoft.edgemac.Dev":     BrowserProfile(name: "Edge Dev",     tabHeight: 40, leftInset: 80, allowFullscreen: true),
    "com.microsoft.edgemac.Canary":  BrowserProfile(name: "Edge Canary",  tabHeight: 40, leftInset: 80, allowFullscreen: true),
    "com.brave.Browser":             BrowserProfile(name: "Brave",        tabHeight: 40, leftInset: 80, allowFullscreen: true),
    "com.brave.Browser.beta":        BrowserProfile(name: "Brave Beta",   tabHeight: 40, leftInset: 80, allowFullscreen: true),
    "com.brave.Browser.nightly":     BrowserProfile(name: "Brave Nightly",tabHeight: 40, leftInset: 80, allowFullscreen: true),
    "com.vivaldi.Vivaldi":           BrowserProfile(name: "Vivaldi",      tabHeight: 40, leftInset: 78, allowFullscreen: true),
    "com.operasoftware.Opera":       BrowserProfile(name: "Opera",        tabHeight: 40, leftInset: 78, allowFullscreen: true),
    "com.operasoftware.OperaGX":     BrowserProfile(name: "Opera GX",     tabHeight: 40, leftInset: 78, allowFullscreen: true),
    "com.operasoftware.OperaNext":   BrowserProfile(name: "Opera Beta",   tabHeight: 40, leftInset: 78, allowFullscreen: true),
    "company.thebrowser.Browser":    BrowserProfile(name: "Arc",          tabHeight: 44, leftInset: 78, allowFullscreen: true),
    // Firefox 系
    "org.mozilla.firefox":           BrowserProfile(name: "Firefox",      tabHeight: 42, leftInset: 78, allowFullscreen: true),
    "org.mozilla.firefoxdeveloperedition": BrowserProfile(name: "Firefox Developer", tabHeight: 42, leftInset: 78, allowFullscreen: true),
    "org.mozilla.nightly":           BrowserProfile(name: "Firefox Nightly", tabHeight: 42, leftInset: 78, allowFullscreen: true),
    "io.github.zen_browser.zen":     BrowserProfile(name: "Zen",          tabHeight: 46, leftInset: 78, allowFullscreen: true),
    // WebKit 系
    "com.apple.Safari":              BrowserProfile(name: "Safari",       tabHeight: 42, leftInset: 78, allowFullscreen: false),
    "com.apple.SafariTechnologyPreview": BrowserProfile(name: "Safari TP", tabHeight: 42, leftInset: 78, allowFullscreen: false),
    "com.kagi.kagimacOS":            BrowserProfile(name: "Orion",        tabHeight: 42, leftInset: 78, allowFullscreen: false),
    "com.duckduckgo.macos.browser":  BrowserProfile(name: "DuckDuckGo",   tabHeight: 44, leftInset: 78, allowFullscreen: true),
]

// ===== 路径 =====
let supportDir = NSString(string: "~/Library/Application Support/TabDoubleClick").expandingTildeInPath
let configPath = (supportDir as NSString).appendingPathComponent("config.json")
let statsPath  = (supportDir as NSString).appendingPathComponent("stats.json")
let logPath    = NSString(string: "~/Library/Logs/TabDoubleClick.log").expandingTildeInPath

// ===== 运行时状态 =====
var profiles: [String: BrowserProfile] = defaultProfiles

struct Settings {
    var cooldown: Double = 0.4   // 两次关闭之间的最短间隔（秒），防手抖连击
    var sound: Bool = false      // 关闭时播放轻提示音
}
var settings = Settings()

let leftInsetFullscreen: CGFloat = 6
let rightInset: CGFloat = 12
let logMaxBytes: UInt64 = 512 * 1024

// ===== 日志（带自动轮转） =====
func rotateLogIfNeeded() {
    let fm = FileManager.default
    guard let attrs = try? fm.attributesOfItem(atPath: logPath),
          let size = attrs[.size] as? UInt64, size > logMaxBytes else { return }
    let old = logPath + ".1"
    try? fm.removeItem(atPath: old)
    try? fm.moveItem(atPath: logPath, toPath: old)
}

func logLine(_ s: String) {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd HH:mm:ss"
    let line = "[\(f.string(from: Date()))] \(s)\n"
    if let h = FileHandle(forWritingAtPath: logPath) {
        h.seekToEndOfFile()
        h.write(line.data(using: .utf8)!)
        h.closeFile()
    } else {
        try? line.write(toFile: logPath, atomically: true, encoding: .utf8)
    }
}

// ===== 统计 =====
struct Stats {
    var date: String = ""
    var today: Int = 0
    var total: Int = 0
}
let dayFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd"
    return f
}()

func loadStats() -> Stats {
    var s = Stats()
    if let data = FileManager.default.contents(atPath: statsPath),
       let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] {
        s.date = (obj["date"] as? String) ?? ""
        s.today = (obj["today"] as? NSNumber)?.intValue ?? 0
        s.total = (obj["total"] as? NSNumber)?.intValue ?? 0
    }
    let today = dayFormatter.string(from: Date())
    if s.date != today { s.date = today; s.today = 0 }
    return s
}

func saveStats(_ s: Stats) {
    try? FileManager.default.createDirectory(atPath: supportDir, withIntermediateDirectories: true)
    let obj: [String: Any] = ["date": s.date, "today": s.today, "total": s.total]
    if let d = try? JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .sortedKeys]) {
        try? d.write(to: URL(fileURLWithPath: statsPath))
    }
}

var stats = Stats()
func bumpStats() {
    let today = dayFormatter.string(from: Date())
    if stats.date != today { stats.date = today; stats.today = 0 }
    stats.today += 1
    stats.total += 1
    saveStats(stats)
}

// ===== 配置读写 =====
func rawConfigObject() -> [String: Any] {
    if let data = FileManager.default.contents(atPath: configPath),
       let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] {
        return obj
    }
    return [:]
}

func writeConfigObject(_ obj: [String: Any]) {
    try? FileManager.default.createDirectory(atPath: supportDir, withIntermediateDirectories: true)
    if let d = try? JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .sortedKeys]) {
        try? d.write(to: URL(fileURLWithPath: configPath))
    }
}

func writeDefaultConfigIfNeeded() {
    try? FileManager.default.createDirectory(atPath: supportDir, withIntermediateDirectories: true)
    guard !FileManager.default.fileExists(atPath: configPath) else { return }
    var obj: [String: Any] = ["_settings": ["cooldown": 0.4, "sound": false]]
    for (bid, p) in defaultProfiles {
        obj[bid] = ["name": p.name,
                    "tabHeight": Double(p.tabHeight),
                    "leftInset": Double(p.leftInset),
                    "allowFullscreen": p.allowFullscreen]
    }
    writeConfigObject(obj)
}

func parseSettings(_ raw: Any?) {
    guard let d = raw as? [String: Any] else { return }
    if let c = (d["cooldown"] as? NSNumber)?.doubleValue, c >= 0 { settings.cooldown = c }
    if let s = d["sound"] as? Bool { settings.sound = s }
}

func loadConfig() {
    var merged = defaultProfiles
    let obj = rawConfigObject()
    if obj.isEmpty {
        profiles = merged
        logLine("未找到配置文件，使用内置默认值（\(merged.count) 款浏览器）")
        return
    }
    parseSettings(obj["_settings"])
    for (bid, raw) in obj where !bid.hasPrefix("_") {
        guard let d = raw as? [String: Any] else { continue }
        let base = defaultProfiles[bid]
        let name = (d["name"] as? String) ?? base?.name ?? bid
        let h = (d["tabHeight"] as? NSNumber)?.doubleValue ?? Double(base?.tabHeight ?? 40)
        let l = (d["leftInset"] as? NSNumber)?.doubleValue ?? Double(base?.leftInset ?? 80)
        let f = (d["allowFullscreen"] as? Bool) ?? base?.allowFullscreen ?? true
        merged[bid] = BrowserProfile(name: name, tabHeight: CGFloat(h), leftInset: CGFloat(l), allowFullscreen: f)
    }
    profiles = merged
    logLine("配置已加载：\(profiles.count) 款浏览器，冷却 \(settings.cooldown)s，提示音 \(settings.sound ? "开" : "关")")
}

func persistProfile(_ bid: String, _ p: BrowserProfile) {
    var obj = rawConfigObject()
    if obj["_settings"] == nil { obj["_settings"] = ["cooldown": settings.cooldown, "sound": settings.sound] }
    obj[bid] = ["name": p.name,
                "tabHeight": Double(p.tabHeight),
                "leftInset": Double(p.leftInset),
                "allowFullscreen": p.allowFullscreen]
    writeConfigObject(obj)
    profiles[bid] = p
}

// ===== 窗口信息 =====
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

func showAlert(_ title: String, _ text: String) {
    NSApp.activate(ignoringOtherApps: true)
    let a = NSAlert()
    a.messageText = title
    a.informativeText = text
    a.alertStyle = .informational
    a.addButton(withTitle: "好")
    a.runModal()
}

// ===== 主逻辑 =====
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    var statusItem: NSStatusItem?
    var monitor: Any?
    var enabled = true
    var lastClose = Date.distantPast
    var menuItemEnable: NSMenuItem?
    var menuItemStatus: NSMenuItem?
    var menuItemStats: NSMenuItem?
    var menuItemFront: NSMenuItem?
    var menuItemScope: NSMenuItem?
    var permissionTimer: Timer?
    var lastTrusted: Bool?
    var calibratingUntil: Date?

    func applicationDidFinishLaunching(_ notification: Notification) {
        rotateLogIfNeeded()
        writeDefaultConfigIfNeeded()
        loadConfig()
        stats = loadStats()
        logLine("TabDoubleClick v\(appVersion) 启动")

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.title = "⇥"
        statusItem?.button?.toolTip = "双击标签栏关闭标签"

        let menu = NSMenu()
        menu.delegate = self

        let item = NSMenuItem(title: "已启用", action: #selector(toggleEnabled), keyEquivalent: "")
        menu.addItem(item)
        menuItemEnable = item

        let status = NSMenuItem(title: "权限：检测中…", action: nil, keyEquivalent: "")
        status.isEnabled = false
        menu.addItem(status)
        menuItemStatus = status

        let front = NSMenuItem(title: "当前：—", action: nil, keyEquivalent: "")
        front.isEnabled = false
        menu.addItem(front)
        menuItemFront = front

        let st = NSMenuItem(title: "今日已关闭 0 个", action: nil, keyEquivalent: "")
        st.isEnabled = false
        menu.addItem(st)
        menuItemStats = st

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "校准当前浏览器的标签栏…", action: #selector(startCalibration), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "重新加载配置", action: #selector(reloadConfig), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "打开配置文件…", action: #selector(openConfig), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "打开辅助功能设置…", action: #selector(openAccessibility), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "重新检测权限", action: #selector(recheck), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "查看日志…", action: #selector(openLog), keyEquivalent: ""))
        menu.addItem(.separator())

        let scope = NSMenuItem(title: "已适配 \(profiles.count) 款浏览器", action: nil, keyEquivalent: "")
        scope.isEnabled = false
        menu.addItem(scope)
        menuItemScope = scope

        let ver = NSMenuItem(title: "版本 \(appVersion)", action: nil, keyEquivalent: "")
        ver.isEnabled = false
        menu.addItem(ver)

        menu.addItem(NSMenuItem(title: "退出", action: #selector(quit), keyEquivalent: "q"))
        statusItem?.menu = menu

        let prompt = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(prompt)

        refreshPermission(registerIfNeeded: true)
        refreshStatsTitle()

        permissionTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.refreshPermission(registerIfNeeded: true)
        }
    }

    // ----- 权限 -----
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

    // ----- 菜单刷新 -----
    func menuWillOpen(_ menu: NSMenu) {
        refreshPermission(registerIfNeeded: true)
        refreshStatsTitle()
        menuItemEnable?.title = enabled ? "已启用" : "已停用"
        menuItemScope?.title = "已适配 \(profiles.count) 款浏览器"
        if let front = NSWorkspace.shared.frontmostApplication,
           let bid = front.bundleIdentifier {
            let name = front.localizedName ?? bid
            if let p = profiles[bid] {
                menuItemFront?.title = "当前：\(name)（已适配 · 标签栏 \(Int(p.tabHeight))px）"
            } else {
                menuItemFront?.title = "当前：\(name)（未适配，可用「校准」添加）"
            }
        }
    }

    func refreshStatsTitle() {
        menuItemStats?.title = "今日已关闭 \(stats.today) 个（累计 \(stats.total)）"
    }

    // ----- 核心判定 -----
    func handle(_ event: NSEvent) {
        guard enabled, event.clickCount == 2 else { return }
        guard let front = NSWorkspace.shared.frontmostApplication,
              let bid = front.bundleIdentifier else { return }
        guard let cg = CGEvent(source: nil)?.location else { return }
        let point = CGPoint(x: cg.x, y: cg.y)

        let windows = axWindows(pid: front.processIdentifier)
        guard let win = windows.first(where: { $0.frame.contains(point) }) ?? windows.first else { return }

        // 校准模式：下一次双击就是样本
        if let until = calibratingUntil, Date() < until {
            performCalibration(bid: bid,
                               appName: front.localizedName ?? bid,
                               point: point,
                               win: win)
            return
        }

        guard Date().timeIntervalSince(lastClose) > settings.cooldown else { return }
        guard let profile = profiles[bid] else { return }

        if win.fullscreen && !profile.allowFullscreen {
            logLine("\(profile.name)：全屏模式已跳过（标签栏会隐藏，避免误关）")
            return
        }

        let inset = win.fullscreen ? leftInsetFullscreen : profile.leftInset
        let relY = point.y - win.frame.minY
        let hitX = point.x >= win.frame.minX + inset && point.x <= win.frame.maxX - rightInset
        let hitY = relY >= 0 && relY <= profile.tabHeight

        logLine("\(profile.name) 双击 点=(\(Int(point.x)),\(Int(point.y))) 距顶=\(Int(relY))px 窗口=(\(Int(win.frame.minX)),\(Int(win.frame.minY)),\(Int(win.frame.width))x\(Int(win.frame.height))) 全屏=\(win.fullscreen) 命中=\(hitX && hitY)")

        guard hitX && hitY else { return }

        lastClose = Date()
        sendCmdW()
        bumpStats()
        refreshStatsTitle()
        if settings.sound { NSSound(named: NSSound.Name("Tink"))?.play() }
        logLine("→ 已发送 ⌘W（\(profile.name)）")
    }

    // ----- 校准 -----
    func performCalibration(bid: String, appName: String, point: CGPoint, win: WinInfo) {
        calibratingUntil = nil
        if win.fullscreen {
            logLine("校准失败：窗口处于全屏")
            showAlert("校准失败", "当前窗口处于全屏状态，标签栏位置会变化。\n请先退出全屏（⌃⌘F），再重新校准。")
            return
        }
        let relY = point.y - win.frame.minY
        let relX = point.x - win.frame.minX

        var p = profiles[bid] ?? BrowserProfile(name: appName, tabHeight: 40, leftInset: 78, allowFullscreen: true)
        // 往下多留 14px，覆盖整行标签的点击范围
        p.tabHeight = max(relY + 14, 26)
        // 如果点的位置比当前左侧避让更靠左，说明该浏览器标签从更左边开始
        if relX < p.leftInset + 8 {
            p.leftInset = max(6, relX - 24)
        }
        persistProfile(bid, p)
        logLine("校准完成：\(p.name) [\(bid)] 距顶=\(Int(relY))px → tabHeight=\(Int(p.tabHeight)), leftInset=\(Int(p.leftInset))")
        showAlert("校准完成 ✅",
                  "\(p.name)：标签栏高度 \(Int(p.tabHeight))px，左侧避让 \(Int(p.leftInset))px。\n\n已写入配置文件，立即生效。现在回到该浏览器，在任意标签上双击试试。")
    }

    // ----- 菜单动作 -----
    @objc func startCalibration() {
        guard let front = NSWorkspace.shared.frontmostApplication,
              let bid = front.bundleIdentifier else {
            showAlert("无法校准", "没有检测到当前应用，请先切换到浏览器窗口。")
            return
        }
        let name = front.localizedName ?? bid
        showAlert("校准 \(name) 的标签栏",
                  "接下来的操作会量出 \(name) 标签栏的真实位置。\n\n步骤：\n1. 点「好」\n2. 切到 \(name) 窗口\n3. 在标签栏的任意一个标签上双击左键\n\n（20 秒内有效；该次双击只用于测量，不会关闭标签）")
        calibratingUntil = Date().addingTimeInterval(20)
        logLine("进入校准模式：等待 \(name) 的标签栏双击样本")
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
        refreshStatsTitle()
    }

    @objc func openConfig() {
        writeDefaultConfigIfNeeded()
        NSWorkspace.shared.open(URL(fileURLWithPath: configPath))
    }

    @objc func openLog() {
        if !FileManager.default.fileExists(atPath: logPath) { logLine("日志已创建") }
        NSWorkspace.shared.open(URL(fileURLWithPath: logPath))
    }

    @objc func quit() { NSApp.terminate(nil) }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
