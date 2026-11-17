import Foundation
import PufferCore
import WebKit

/// Reads Krillion's own localStorage from inside the web view and hands it to DiveDetector.
final class KrillionBridge: NSObject, WKScriptMessageHandler {
    static let handlerName = "puffer"
    private let onSnapshot: ([String: String]?) -> Void

    init(onSnapshot: @escaping ([String: String]?) -> Void) {
        self.onSnapshot = onSnapshot
    }

    func install(in controller: WKUserContentController) {
        controller.add(self, name: Self.handlerName)
        controller.addUserScript(WKUserScript(
            source: Self.script, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
    }

    /// Body is a {key: value} snapshot, or {"__error": "..."} when storage couldn't be read.
    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        // Only Krillion's own top-level page may report progress; ad frames inside it can't.
        guard message.frameInfo.isMainFrame, message.frameInfo.securityOrigin.host == KrillionURL.host else {
            NSLog("Puffer Pal: ignored a bridge message from \(message.frameInfo.securityOrigin.host)")
            return
        }
        guard let body = message.body as? [String: Any], body["__error"] == nil else {
            onSnapshot(nil)
            return
        }
        onSnapshot(body.compactMapValues { $0 as? String })
    }

    private static let script = """
    (function () {
      if (location.hostname !== "\(KrillionURL.host)") return;
      const watched = (k) => k.startsWith("krillion:"); // mirrors DiveDetector.isWatched
      const post = (m) => window.webkit.messageHandlers.\(handlerName).postMessage(m);
      function snap() {
        try {
          const out = {};
          for (let i = 0; i < localStorage.length; i++) {
            const k = localStorage.key(i);
            if (k && watched(k)) out[k] = localStorage.getItem(k);
          }
          post(out);
        } catch (e) { post({ __error: String(e) }); }
      }
      const soon = () => setTimeout(snap, 100);
      window.addEventListener("krillion:progress-changed", soon);
      window.addEventListener("krillion:progress-downloaded", soon);
      document.addEventListener("visibilitychange", snap);
      setInterval(() => { if (document.visibilityState === "visible") snap(); }, 30000);
      snap();
    })();
    """
}
