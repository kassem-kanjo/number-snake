// Number Snake for macOS: one window holding a WKWebView that shows the bundled index.html.
// Plain AppKit, no storyboard or xib: the window and menus are built in code.
import AppKit
import WebKit

// Same near-black as the page's own background, so there is no white flash at launch.
let pageColour = NSColor(srgbRed: 0x0b / 255, green: 0x0b / 255, blue: 0x0c / 255, alpha: 1)

final class AppDelegate: NSObject, NSApplicationDelegate, WKNavigationDelegate, WKDownloadDelegate {
    var window: NSWindow!
    var webView: WKWebView!
    // WKDownload only keeps a weak reference to us, so remember each download's target file here.
    var downloads: [WKDownload: URL] = [:]

    var pageURL: URL { Bundle.main.url(forResource: "index", withExtension: "html")! }

    // MARK: start-up

    func applicationDidFinishLaunching(_ note: Notification) {
        buildMenus()

        let config = WKWebViewConfiguration()
        // Lets the page's own F key (requestFullscreen) work inside the web view.
        if #available(macOS 12.3, *) { config.preferences.isElementFullscreenEnabled = true }

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.underPageBackgroundColor = pageColour
        webView.setValue(false, forKey: "drawsBackground")   // show the window's dark colour until the page paints

        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1100, height: 760),
                          styleMask: [.titled, .closable, .miniaturizable, .resizable],
                          backing: .buffered, defer: false)
        window.title = "Number Snake"
        window.minSize = NSSize(width: 420, height: 320)
        window.appearance = NSAppearance(named: .darkAqua)   // dark title bar
        window.backgroundColor = pageColour
        window.collectionBehavior = [.fullScreenPrimary]      // native macOS full screen
        window.isReleasedWhenClosed = false
        window.contentView = webView
        // Remember the window's size and place between launches; centre it the first time.
        if !window.setFrameUsingName("NumberSnakeMainWindow") { window.center() }
        window.setFrameAutosaveName("NumberSnakeMainWindow")

        loadPage()
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(webView)   // so Space, R and F reach the page straight away
        NSApp.activate(ignoringOtherApps: true)
    }

    // Closing the only window ends the app; the simulation has no reason to keep running unseen.
    func applicationShouldTerminateAfterLastWindowClosed(_ app: NSApplication) -> Bool { true }

    // A fresh load every time (never the current URL), so Reload always means a new run.
    func loadPage() {
        webView.loadFileURL(pageURL, allowingReadAccessTo: pageURL.deletingLastPathComponent())
    }

    @objc func reload(_ sender: Any?) { loadPage() }

    // MARK: menus

    func buildMenus() {
        let bar = NSMenu()
        func submenu(_ title: String) -> NSMenu {
            let item = NSMenuItem(); bar.addItem(item)
            let menu = NSMenu(title: title); item.submenu = menu
            return menu
        }
        func add(_ menu: NSMenu, _ title: String, _ action: Selector?, _ key: String = "",
                 _ mods: NSEvent.ModifierFlags = .command, target: AnyObject? = nil) {
            let item = menu.addItem(withTitle: title, action: action, keyEquivalent: key)
            item.keyEquivalentModifierMask = mods
            item.target = target
        }

        let app = submenu("Number Snake")
        add(app, "About Number Snake", #selector(NSApplication.orderFrontStandardAboutPanel(_:)))
        app.addItem(.separator())
        add(app, "Hide Number Snake", #selector(NSApplication.hide(_:)), "h")
        add(app, "Hide Others", #selector(NSApplication.hideOtherApplications(_:)), "h", [.command, .option])
        add(app, "Show All", #selector(NSApplication.unhideAllApplications(_:)))
        app.addItem(.separator())
        add(app, "Quit Number Snake", #selector(NSApplication.terminate(_:)), "q")

        let file = submenu("File")
        add(file, "Close", #selector(NSWindow.performClose(_:)), "w")

        let view = submenu("View")
        add(view, "Reload", #selector(reload(_:)), "r", target: self)
        view.addItem(.separator())
        // AppKit renames this to "Exit Full Screen" by itself while the window is full screen.
        add(view, "Enter Full Screen", #selector(NSWindow.toggleFullScreen(_:)), "f", [.command, .control])

        let windowMenu = submenu("Window")
        add(windowMenu, "Minimize", #selector(NSWindow.performMiniaturize(_:)), "m")
        add(windowMenu, "Zoom", #selector(NSWindow.performZoom(_:)))
        windowMenu.addItem(.separator())
        add(windowMenu, "Bring All to Front", #selector(NSApplication.arrangeInFront(_:)))

        NSApp.mainMenu = bar
        NSApp.windowsMenu = windowMenu
    }

    // MARK: navigation and downloads

    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // The Record button clicks an <a download> on a blob: URL; WebKit flags that as a download.
        if action.shouldPerformDownload { decisionHandler(.download); return }
        // Anything that is not our own page goes to the user's browser, not into this window.
        if let url = action.request.url, !url.isFileURL, url.scheme != "about", url.scheme != "blob" {
            NSWorkspace.shared.open(url)
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, decidePolicyFor response: WKNavigationResponse,
                 decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        decisionHandler(response.canShowMIMEType ? .allow : .download)
    }

    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        download.delegate = self
    }

    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        download.delegate = self
    }

    // Save into ~/Downloads under the name the page suggested, adding " 2", " 3"... rather than overwriting.
    func download(_ download: WKDownload, decideDestinationUsing response: URLResponse,
                  suggestedFilename: String, completionHandler: @escaping (URL?) -> Void) {
        let folder = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
        let name = (suggestedFilename as NSString).lastPathComponent   // never let a name climb out of the folder
        let base = (name as NSString).deletingPathExtension, ext = (name as NSString).pathExtension
        var target = folder.appendingPathComponent(name)
        var n = 2
        while FileManager.default.fileExists(atPath: target.path) {
            target = folder.appendingPathComponent(ext.isEmpty ? "\(base) \(n)" : "\(base) \(n).\(ext)")
            n += 1
        }
        downloads[download] = target
        completionHandler(target)
    }

    func downloadDidFinish(_ download: WKDownload) {
        if let file = downloads.removeValue(forKey: download) {
            NSWorkspace.shared.activateFileViewerSelecting([file])   // show the saved clip in Finder
        }
    }

    func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        downloads.removeValue(forKey: download)
        let alert = NSAlert()
        alert.messageText = "The file could not be saved"
        alert.informativeText = error.localizedDescription
        alert.beginSheetModal(for: window)
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.regular)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
