import SwiftUI
import AppKit

// MARK: - Entry point

@main
struct ClaudePulse {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }
}

// MARK: - AppDelegate

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var panel: NSPanel!
    var manager: UsageManager!
    var eventMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        manager = UsageManager()
        manager.onTitleUpdate = { [weak self] attrTitle in
            DispatchQueue.main.async { self?.statusItem.button?.attributedTitle = attrTitle }
        }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let btn = statusItem.button {
            let mono: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedSystemFont(ofSize: 12, weight: .medium)]
            btn.attributedTitle = NSAttributedString(string: "⏱ –  📅 –", attributes: mono)
            btn.action = #selector(togglePanel)
            btn.target = self
        }

        let hosting = NSHostingView(rootView: PulseView(manager: manager))
        hosting.frame = NSRect(x: 0, y: 0, width: 384, height: 340)

        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 384, height: 340),
            styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.statusWindow)) + 1)
        panel.contentView = hosting
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .transient]

        manager.fetch()
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.manager.fetch()
        }
    }

    @objc func togglePanel() {
        panel.isVisible ? hidePanel() : showPanel()
    }

    func showPanel() {
        guard let btn = statusItem.button,
              let btnWindow = btn.window else { return }

        let btnRect = btnWindow.convertToScreen(btn.convert(btn.bounds, to: nil))
        let x = btnRect.midX - panel.frame.width / 2
        let y = btnRect.minY - panel.frame.height - 6

        panel.setFrameOrigin(NSPoint(x: x, y: y))
        panel.makeKeyAndOrderFront(nil)

        eventMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] _ in self?.hidePanel() }
    }

    func hidePanel() {
        panel.orderOut(nil)
        if let m = eventMonitor { NSEvent.removeMonitor(m); eventMonitor = nil }
    }
}

// MARK: - Model

struct Metric {
    var pct: Int = 0
    var resetsAt: Date? = nil
}

class UsageManager: ObservableObject {
    @Published var session   = Metric()
    @Published var weekly    = Metric()
    @Published var sonnet    = Metric()
    @Published var hasSonnet = false
    @Published var loading   = false
    @Published var error: String? = nil
    @Published var updatedAt: Date? = nil

    var onTitleUpdate: ((NSAttributedString) -> Void)?

    private var cookie: String {
        get { UserDefaults.standard.string(forKey: "claude_pulse_cookie") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "claude_pulse_cookie") }
    }
    private var orgId: String {
        get { UserDefaults.standard.string(forKey: "claude_pulse_org") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "claude_pulse_org") }
    }

    func currentCookie() -> String { cookie }
    func currentOrgId()  -> String { orgId }

    func save(cookie c: String, orgId o: String) { cookie = c; orgId = o; fetch() }

    func fetch() {
        guard !cookie.isEmpty else { error = "Cookie not set — click ⚙"; return }
        loading = true; error = nil
        Task { await doFetch() }
    }

    @MainActor
    private func doFetch() async {
        do {
            let oid = orgId.isEmpty ? try await resolveOrgId() : orgId
            let r   = try await loadUsage(orgId: oid)
            session = r.session; weekly = r.weekly; sonnet = r.sonnet
            hasSonnet = r.hasSonnet; updatedAt = Date(); loading = false
            pushTitle()
        } catch {
            self.error = error.localizedDescription; loading = false
        }
    }

    private func pushTitle() {
        onTitleUpdate?(makeMenuTitle(sPct: session.pct, wPct: weekly.pct))
    }

    private func makeMenuTitle(sPct: Int, wPct: Int) -> NSAttributedString {
        let textAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .medium)
        ]
        let s = NSMutableAttributedString()

        func attach(_ img: NSImage?, w: CGFloat = 15, dy: CGFloat = -3) -> NSAttributedString {
            let a = NSTextAttachment()
            a.image = img
            a.bounds = CGRect(x: 0, y: dy, width: w, height: w)
            return NSAttributedString(attachment: a)
        }

        // Hourglass — template = white on dark menu bar, black on light
        let hourglassCfg = NSImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        let clockImg = NSImage(systemSymbolName: "hourglass", accessibilityDescription: nil)?
            .withSymbolConfiguration(hourglassCfg)

        // Calendar page with "7"
        let calImg = numberedCalendarImage(number: 7, size: 15)

        s.append(attach(clockImg))
        s.append(NSAttributedString(string: " \(sPct)%  ", attributes: textAttrs))
        s.append(attach(calImg, w: 16))
        s.append(NSAttributedString(string: " \(wPct)%", attributes: textAttrs))
        return s
    }

    private func numberedCalendarImage(number: Int, size: CGFloat) -> NSImage {
        let result = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            let r = rect.width * 0.18  // corner radius

            // White body
            let bodyPath = NSBezierPath(roundedRect: rect, xRadius: r, yRadius: r)
            NSColor.white.setFill()
            bodyPath.fill()

            // Blue header strip (~28% from top), clipped to rounded rect
            let hh = rect.height * 0.28
            NSGraphicsContext.saveGraphicsState()
            bodyPath.setClip()
            NSColor(red: 0.88, green: 0.18, blue: 0.18, alpha: 1).setFill()
            NSBezierPath(rect: NSRect(x: 0, y: rect.height - hh, width: rect.width, height: hh)).fill()
            NSGraphicsContext.restoreGraphicsState()

            // Bold "7" centred in the white body area
            let bodyH = rect.height - hh
            let numStr = NSAttributedString(string: "\(number)", attributes: [
                .font: NSFont.boldSystemFont(ofSize: rect.height * 0.52),
                .foregroundColor: NSColor(red: 0.10, green: 0.12, blue: 0.20, alpha: 1)
            ])
            let ns = numStr.size()
            numStr.draw(at: NSPoint(
                x: rect.width / 2 - ns.width  / 2,
                y: bodyH / 2    - ns.height / 2
            ))
            return true
        }
        result.isTemplate = false
        return result
    }

    private let ua = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15"

    private func req(_ url: URL) -> URLRequest {
        var r = URLRequest(url: url)
        r.setValue(cookie,               forHTTPHeaderField: "Cookie")
        r.setValue("application/json",   forHTTPHeaderField: "Accept")
        r.setValue(ua,                   forHTTPHeaderField: "User-Agent")
        r.setValue("https://claude.ai",  forHTTPHeaderField: "Referer")
        r.setValue("web_claude_ai",      forHTTPHeaderField: "anthropic-client-platform")
        r.setValue("1.0.0",              forHTTPHeaderField: "anthropic-client-version")
        return r
    }

    private func resolveOrgId() async throws -> String {
        for part in cookie.split(separator: ";") {
            let t = part.trimmingCharacters(in: .whitespaces)
            if t.hasPrefix("lastActiveOrg=") { return String(t.dropFirst(14)) }
        }
        let (data, _) = try await URLSession.shared.data(for: req(URL(string: "https://claude.ai/api/bootstrap")!))
        guard let j = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let a = j["account"] as? [String: Any],
              let o = a["lastActiveOrgId"] as? String else { throw AppError.noOrgId }
        return o
    }

    struct ParsedUsage { var session, weekly, sonnet: Metric; var hasSonnet: Bool }

    private func loadUsage(orgId: String) async throws -> ParsedUsage {
        let url = URL(string: "https://claude.ai/api/organizations/\(orgId)/usage")!
        let (data, resp) = try await URLSession.shared.data(for: req(url))
        if let h = resp as? HTTPURLResponse, h.statusCode != 200 { throw AppError.httpError(h.statusCode) }
        guard let j = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { throw AppError.badJSON }

        func parse(_ key: String) -> Metric? {
            guard let b = j[key] as? [String: Any] else { return nil }
            let pct = Int((b["utilization"] as? Double) ?? 0)
            var date: Date? = nil
            if let s = b["resets_at"] as? String {
                let f = ISO8601DateFormatter(); f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                date = f.date(from: s) ?? ISO8601DateFormatter().date(from: s)
            }
            return Metric(pct: pct, resetsAt: date)
        }

        return ParsedUsage(
            session: parse("five_hour") ?? Metric(),
            weekly:  parse("seven_day") ?? Metric(),
            sonnet:  parse("seven_day_sonnet") ?? Metric(),
            hasSonnet: j["seven_day_sonnet"] is [String: Any]
        )
    }
}

enum AppError: LocalizedError {
    case noOrgId, badJSON, httpError(Int)
    var errorDescription: String? {
        switch self {
        case .noOrgId:          return "Could not find org ID"
        case .badJSON:          return "Unexpected API response"
        case .httpError(let c): return "HTTP \(c) — cookie may have expired"
        }
    }
}

// MARK: - Main View

struct PulseView: View {
    @ObservedObject var manager: UsageManager

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "0b1628"), Color(hex: "0d2340"), Color(hex: "091422")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.07), lineWidth: 1)
                )

            VStack(spacing: 0) {
                headerView
                Divider().overlay(Color.white.opacity(0.07))
                metricsView
                Divider().overlay(Color.white.opacity(0.07))
                footerView
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .shadow(color: .black.opacity(0.6), radius: 24, x: 0, y: 8)
    }

    var headerView: some View {
        HStack {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color(hex: "4f9cf9"))
                    .frame(width: 6, height: 6)
                    .shadow(color: Color(hex: "4f9cf9"), radius: 5)
                Text("CLAUDE USAGE")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.65))
                    .kerning(1.5)
            }
            Spacer()
            if manager.loading {
                ProgressView().scaleEffect(0.5).frame(width: 14, height: 14).tint(.white.opacity(0.3))
            } else if let t = manager.updatedAt {
                Text(t, style: .time)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.45))
            }
        }
        .padding(.horizontal, 18).padding(.top, 18).padding(.bottom, 14)
        .background(Color.white.opacity(0.02))
    }

    var metricsView: some View {
        VStack(spacing: 0) {
            MetricRow(label: "Session", metric: manager.session,                        icon: "clock.fill")
            Divider().overlay(Color.white.opacity(0.04)).padding(.horizontal, 18)
            MetricRow(label: "Weekly",  metric: manager.weekly,                         icon: "calendar")
            Divider().overlay(Color.white.opacity(0.04)).padding(.horizontal, 18)
            MetricRow(label: "Sonnet",  metric: manager.hasSonnet ? manager.sonnet : nil, icon: "sparkles")
            if let err = manager.error {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 10)).foregroundStyle(.red.opacity(0.7))
                    Text(err).font(.system(size: 10)).foregroundStyle(.red.opacity(0.7))
                }
                .padding(.horizontal, 18).padding(.vertical, 8)
            }
        }
    }

    var footerView: some View {
        HStack {
            FooterBtn(icon: "arrow.clockwise", label: "Refresh") { manager.fetch() }
            Spacer()
            FooterBtn(icon: "key.fill",        label: "Cookie")  { showDialog() }
            FooterBtn(icon: "power",            label: "Quit")    { NSApplication.shared.terminate(nil) }
        }
        .padding(.horizontal, 14).padding(.top, 10).padding(.bottom, 16)
        .background(Color.white.opacity(0.02))
    }

    func showDialog() {
        NSApp.activate(ignoringOtherApps: true)
        let a1 = NSAlert()
        a1.messageText = "Session Cookie"
        a1.informativeText = "Paste the full Cookie: header from claude.ai DevTools\n(Network → any request → Request Headers → Cookie:)"
        a1.addButton(withTitle: "Next →"); a1.addButton(withTitle: "Cancel")
        let f1 = NSTextField(frame: NSRect(x: 0, y: 0, width: 420, height: 22))
        f1.stringValue = manager.currentCookie()
        f1.placeholderString = "sessionKey=sk-ant-…"
        f1.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        a1.accessoryView = f1
        guard a1.runModal() == .alertFirstButtonReturn else { return }

        let a2 = NSAlert()
        a2.messageText = "Organisation ID"
        a2.informativeText = "Paste org ID from the request URL:\n/api/organizations/[THIS-ID]/usage"
        a2.addButton(withTitle: "Save"); a2.addButton(withTitle: "Cancel")
        let f2 = NSTextField(frame: NSRect(x: 0, y: 0, width: 320, height: 22))
        f2.stringValue = manager.currentOrgId()
        f2.placeholderString = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
        f2.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        a2.accessoryView = f2
        guard a2.runModal() == .alertFirstButtonReturn else { return }

        let c = f1.stringValue.trimmingCharacters(in: .whitespaces)
        let o = f2.stringValue.trimmingCharacters(in: .whitespaces)
        if !c.isEmpty { manager.save(cookie: c, orgId: o) }
    }
}

// MARK: - MetricRow

struct MetricRow: View {
    let label: String
    let metric: Metric?   // nil = not available on this plan
    let icon: String

    var pct: Int { metric?.pct ?? 0 }

    var accent: Color {
        guard metric != nil else { return Color.white.opacity(0.2) }
        return pct >= 90 ? Color(hex: "ff4d4d") :
               pct >= 70 ? Color(hex: "ffa94d") : Color(hex: "4f9cf9")
    }
    var dot: Color {
        guard metric != nil else { return Color.white.opacity(0.15) }
        return pct >= 90 ? Color(hex: "ff4d4d") :
               pct >= 70 ? Color(hex: "ffa94d") : Color(hex: "4ade80")
    }
    var barColors: [Color] {
        pct >= 90 ? [Color(hex: "ff4d4d"), Color(hex: "ff7676")] :
        pct >= 70 ? [Color(hex: "ffa94d"), Color(hex: "ffd580")] :
                    [Color(hex: "1d4ed8"), Color(hex: "4f9cf9")]
    }

    var body: some View {
        VStack(spacing: 7) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(accent.opacity(0.8))
                    .frame(width: 13)
                Text(label.uppercased())
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.75))
                    .kerning(0.8)
                Spacer()
                if let m = metric {
                    Text("\(m.pct)%")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(accent)
                } else {
                    Text("–")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.2))
                }
                Circle()
                    .fill(dot)
                    .frame(width: 7, height: 7)
                    .shadow(color: dot.opacity(0.9), radius: metric != nil ? 5 : 0)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 5)
                    if metric != nil {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(LinearGradient(colors: barColors, startPoint: .leading, endPoint: .trailing))
                            .frame(width: max(geo.size.width * CGFloat(pct) / 100, 0), height: 5)
                            .shadow(color: accent.opacity(0.6), radius: 4, x: 0, y: 0)
                    }
                }
            }
            .frame(height: 5)

            HStack {
                Text(resetLabel)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.45))
                Spacer()
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 11)
    }

    var resetLabel: String {
        guard let m = metric else { return "not available on this plan" }
        guard let d = m.resetsAt else { return "–" }
        let s = Int(d.timeIntervalSinceNow)
        guard s > 0 else { return "now" }
        let h = s / 3600; let m2 = (s % 3600) / 60
        return "resets in \(h > 0 ? "\(h)h \(m2)m" : "\(m2)m")"
    }
}

// MARK: - Footer button

struct FooterBtn: View {
    let icon: String; let label: String; let action: () -> Void
    @State private var hov = false
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 10))
                Text(label).font(.system(size: 10, design: .monospaced))
            }
            .foregroundStyle(hov ? Color.white.opacity(0.75) : Color.white.opacity(0.3))
            .padding(.horizontal, 8).padding(.vertical, 5)
            .background(hov ? Color.white.opacity(0.07) : .clear)
            .clipShape(RoundedRectangle(cornerRadius: 5))
        }
        .buttonStyle(.plain)
        .onHover { hov = $0 }
    }
}

// MARK: - Hex color

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var n: UInt64 = 0; Scanner(string: h).scanHexInt64(&n)
        self.init(red: Double((n >> 16) & 0xFF) / 255,
                  green: Double((n >>  8) & 0xFF) / 255,
                  blue:  Double( n        & 0xFF) / 255)
    }
}
