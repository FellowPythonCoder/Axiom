import SwiftUI
import WebKit
#if canImport(UIKit)
import UIKit
#endif

struct ContentView: View {
    var body: some View {
        AxiomWebView()
            .ignoresSafeArea()
            .background(Color(red: 0.965, green: 0.925, blue: 0.839))
    }
}

struct AxiomWebView {
    func makeCoordinator() -> Coordinator { Coordinator() }

    fileprivate func makeWebView(_ coordinator: Coordinator) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.userContentController.add(coordinator, name: "haptic")

        let web = WKWebView(frame: .zero, configuration: config)
        coordinator.web = web
        #if os(iOS)
        web.isOpaque = false
        web.backgroundColor = .clear
        web.scrollView.backgroundColor = .clear
        web.scrollView.bounces = false
        web.scrollView.contentInsetAdjustmentBehavior = .never
        web.scrollView.showsVerticalScrollIndicator = false
        web.scrollView.showsHorizontalScrollIndicator = false
        #else
        web.setValue(false, forKey: "drawsBackground")
        #endif
        web.allowsLinkPreview = false
        if #available(iOS 16.4, macOS 13.3, *) { web.isInspectable = true }

        if let url = Bundle.main.url(forResource: "index", withExtension: "html") {
            web.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
        return web
    }

    final class Coordinator: NSObject, WKScriptMessageHandler {
        weak var web: WKWebView?

        #if os(iOS)
        private let light = UIImpactFeedbackGenerator(style: .light)
        private let medium = UIImpactFeedbackGenerator(style: .medium)
        private let heavy = UIImpactFeedbackGenerator(style: .heavy)
        private let select = UISelectionFeedbackGenerator()
        private let notify = UINotificationFeedbackGenerator()
        #endif // os(iOS)

        func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
            #if os(iOS)
            guard let kind = message.body as? String else { return }
            switch kind {
            case "light":     light.impactOccurred()
            case "medium":    medium.impactOccurred()
            case "heavy":     heavy.impactOccurred()
            case "selection": select.selectionChanged()
            case "success":   notify.notificationOccurred(.success)
            case "warning":   notify.notificationOccurred(.warning)
            case "error":     notify.notificationOccurred(.error)
            default: break
            }
            #endif // os(iOS)
        }
    }
}

#if os(iOS)
extension AxiomWebView: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView { makeWebView(context.coordinator) }
    func updateUIView(_ web: WKWebView, context: Context) {}
}
#else
extension AxiomWebView: NSViewRepresentable {
    func makeNSView(context: Context) -> WKWebView { makeWebView(context.coordinator) }
    func updateNSView(_ web: WKWebView, context: Context) {}
}
#endif
