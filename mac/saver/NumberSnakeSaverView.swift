// Number Snake screensaver: a ScreenSaverView that shows the bundled page in a WKWebView.
//
// Screensavers on recent macOS run inside the "legacyScreenSaver" process, which can create
// several instances of a view and does not reliably call stopAnimation. So this file:
//   - makes the web view lazily, once per start, and never twice at the same time;
//   - tears it down (stops loading, blanks the page, removes it) on stopAnimation, on the
//     "com.apple.screensaver.willstop" notification, and when the view is deallocated;
//   - keeps the web view away from mouse and keyboard so any input dismisses the saver as usual.
import ScreenSaver
import WebKit

// A web view that never receives input: clicks and keys fall through to the saver window.
final class PassiveWebView: WKWebView {
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
    override var acceptsFirstResponder: Bool { false }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { false }
}

// The class name is fixed with @objc so the Info.plist can name it without a module prefix.
@objc(NumberSnakeSaverView)
final class NumberSnakeSaverView: ScreenSaverView, WKNavigationDelegate {
    private var web: WKWebView?
    private var fellBack = false
    private let pageColour = NSColor(srgbRed: 0x0b / 255, green: 0x0b / 255, blue: 0x0c / 255, alpha: 1)

    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        wantsLayer = true
        animationTimeInterval = 1.0 / 30.0   // how often animateOneFrame is called
        layer?.backgroundColor = pageColour.cgColor   // dark from the first frame, even before the page loads
        // macOS tells us when the saver is about to end; stopAnimation alone is not dependable.
        DistributedNotificationCenter.default().addObserver(
            self, selector: #selector(willStop(_:)),
            name: Notification.Name("com.apple.screensaver.willstop"), object: nil)
    }

    deinit {
        DistributedNotificationCenter.default().removeObserver(self)
        // deinit is not guaranteed to run on the main thread; only the web view's own teardown needs it.
        let leftover = web
        DispatchQueue.main.async { leftover?.stopLoading(); leftover?.removeFromSuperview() }
    }

    // MARK: lifecycle

    override func startAnimation() {
        super.startAnimation()
        makeWebViewIfNeeded()
    }

    override func stopAnimation() {
        super.stopAnimation()
        tearDown()
    }

    @objc private func willStop(_ note: Notification) {
        DispatchQueue.main.async { [weak self] in self?.tearDown() }
    }

    // WebKit does not run a page's own animation frames inside the screensaver host, because the
    // system does not count the web view as visible. So the saver's frame callback drives the page.
    override func animateOneFrame() {
        web?.evaluateJavaScript("window.numberSnakeStep && window.numberSnakeStep()", completionHandler: nil)
    }
    override var hasConfigureSheet: Bool { false }
    override var configureSheet: NSWindow? { nil }

    // MARK: web view

    private func makeWebViewIfNeeded() {
        guard web == nil else { return }
        let config = WKWebViewConfiguration()
        // Safety net in case the page lacks its own ?saver=1 handling: no cursor, no controls.
        let css = "html,body,*{cursor:none !important} #dock,#tip{display:none !important}"
        let js = "var s=document.createElement('style');s.textContent='\(css)';document.documentElement.appendChild(s);"
        config.userContentController.addUserScript(
            WKUserScript(source: js, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        let view = PassiveWebView(frame: bounds, configuration: config)
        view.autoresizingMask = [.width, .height]
        view.navigationDelegate = self
        view.underPageBackgroundColor = pageColour
        view.setValue(false, forKey: "drawsBackground")
        // The small preview in System Settings is only a few hundred points wide: zoom out so it
        // shows a recognisable grid instead of three giant cells.
        if isPreview { view.pageZoom = 0.5 }

        addSubview(view)
        web = view
        load(in: view)
    }

    private func pageURL() -> URL? {
        let bundle = Bundle(for: NumberSnakeSaverView.self)   // not Bundle.main: that is legacyScreenSaver
        return bundle.url(forResource: "index", withExtension: "html")
    }

    private func load(in view: WKWebView) {
        guard let file = pageURL(), var parts = URLComponents(url: file, resolvingAgainstBaseURL: false) else { return }
        parts.query = "saver=1"
        if let url = parts.url {
            view.loadFileURL(url, allowingReadAccessTo: file.deletingLastPathComponent())
        }
    }

    // If WebKit's sandbox will not let it read the file, hand it the text directly. Giving the
    // same URL as the base keeps location.search as "?saver=1".
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        guard !fellBack, let file = pageURL(),
              let html = try? String(contentsOf: file, encoding: .utf8),
              var parts = URLComponents(url: file, resolvingAgainstBaseURL: false) else { return }
        fellBack = true
        parts.query = "saver=1"
        webView.loadHTMLString(html, baseURL: parts.url)
    }

    private func tearDown() {
        guard let view = web else { return }
        web = nil
        fellBack = false
        view.navigationDelegate = nil
        view.stopLoading()
        view.loadHTMLString("", baseURL: nil)   // replaces the page so its timers and animation frames stop
        view.removeFromSuperview()
    }
}
