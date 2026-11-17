import AppKit
import Observation
import PufferCore
import SwiftUI
import WebKit

/// What the panel header shows; the app delegate keeps it current.
@Observable
final class PanelModel {
    var roomText = ""
    var lastRoom: String?
    var diveLabel = "Daily Dive"
    var error: String?

    var onJoin: (RoomCode) -> Void = { _ in }
    var onRejoin: () -> Void = {}
    var onDive: () -> Void = {}
    var onHost: () -> Void = {}

    func join() {
        guard let code = RoomCode(roomText) else {
            error = "Room codes are 4 letters"
            return
        }
        error = nil
        roomText = ""
        onJoin(code)
    }
}

struct PanelHeader: View {
    @Bindable var model: PanelModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("🐡").font(.title2)
                TextField("ABCD", text: $model.roomText)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                    .frame(width: 72)
                    .onSubmit { model.join() }
                    .onChange(of: model.roomText) { _, new in
                        let cleaned = String(new.uppercased().filter { $0.isASCII && $0.isLetter }.prefix(4))
                        if cleaned != new { model.roomText = cleaned }
                    }
                Button("Join") { model.join() }.keyboardShortcut(.defaultAction)
                if let last = model.lastRoom {
                    Button("↺ Rejoin \(last)") { model.onRejoin() }
                }
                Spacer()
            }
            HStack(spacing: 8) {
                Button(model.diveLabel) { model.onDive() }
                Button("Host a room") { model.onHost() }
                if let error = model.error {
                    Text(error).foregroundStyle(.red).font(.callout)
                }
                Spacer()
            }
        }
        .padding(10)
    }
}

/// The puffer's window: header over a web view showing krillion.io.
final class PufferPanel: NSPanel, NSWindowDelegate {
    let model = PanelModel()
    let webView: WKWebView
    var onURLChange: (URL) -> Void = { _ in }
    private var urlObservation: NSKeyValueObservation?

    init(bridge: KrillionBridge) {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default() // keeps Krillion's guest player, name and seats
        config.applicationNameForUserAgent = "Version/18.0 Safari/605.1.15"
        bridge.install(in: config.userContentController)
        webView = WKWebView(frame: .zero, configuration: config)

        super.init(contentRect: NSRect(x: 0, y: 0, width: 440, height: 760),
                   styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
                   backing: .buffered, defer: false)
        title = "Puffer Pal"
        titlebarAppearsTransparent = true
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        minSize = NSSize(width: 360, height: 480)
        delegate = self

        let header = NSHostingView(rootView: PanelHeader(model: model))
        let stack = NSStackView(views: [header, webView])
        stack.orientation = .vertical
        stack.spacing = 0
        stack.edgeInsets = NSEdgeInsets(top: 28, left: 0, bottom: 0, right: 0)
        header.setContentHuggingPriority(.required, for: .vertical)
        contentView = stack

        // Krillion routes client-side (pushState), so watch the URL rather than navigations.
        urlObservation = webView.observe(\.url, options: [.new]) { [weak self] view, _ in
            guard let url = view.url else { return }
            DispatchQueue.main.async { self?.onURLChange(url) }
        }
    }

    override var canBecomeKey: Bool { true }

    /// What the window opens next to: the fish pet, or the menu-bar icon.
    enum Anchor {
        case pet(NSWindow)
        case menuBar(NSStatusBarButton?)
    }

    func show(url: URL, near anchor: Anchor) {
        if webView.url != url { webView.load(URLRequest(url: url)) }
        if !isVisible { place(near: anchor) }
        NSApp.activate(ignoringOtherApps: true)
        makeKeyAndOrderFront(nil)
    }

    private func place(near anchor: Anchor) {
        switch anchor {
        case let .pet(pet):
            guard let screen = pet.screen ?? NSScreen.main else { return }
            setFrameTopLeftPoint(PanelPlacement.topLeft(
                nearPet: pet.frame, panelSize: frame.size, visible: screen.visibleFrame))
        case let .menuBar(button):
            guard let iconWindow = button?.window, let screen = iconWindow.screen ?? NSScreen.main else { return }
            let icon = iconWindow.frame
            setFrameTopLeftPoint(PanelPlacement.topLeft(
                anchorMidX: icon.midX, anchorMinY: icon.minY,
                panelWidth: frame.width, visible: screen.visibleFrame))
        }
    }

    /// Closing stops the game entirely so nothing runs in the background.
    func windowWillClose(_ notification: Notification) {
        webView.loadHTMLString("", baseURL: nil)
    }
}
