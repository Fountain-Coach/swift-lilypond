import Foundation
import LilyPondKit
import LilyPondPreview

#if os(macOS)
import AppKit
import SwiftUI

let sample = [
  "\\version \"2.24.0\"",
  "{ c'4 d' e' f' | g'1 }"
].joined(separator: "\n")

@main
struct LPPreviewDemo {
    static func main() async {
        do {
            let kit = LilyPond()
            let art = try await kit.render(source: sample, options: .init(format: .pdf))
            let content: any View
            switch art.visual {
            case .pdf(let data):
                content = PDFPreviewView(data)
            case .svg(let pages):
                content = SVGWebView(pages.first ?? Data())
            case .png:
                print("PNG preview demo not implemented; switching to PDF")
                let art2 = try await kit.render(source: sample, options: .init(format: .pdf))
                if case .pdf(let d) = art2.visual { content = PDFPreviewView(d) } else { content = Text("Failed") }
            }

            let app = NSApplication.shared
            app.setActivationPolicy(.regular)
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 800, height: 1000),
                                  styleMask: [.titled, .closable, .resizable],
                                  backing: .buffered, defer: false)
            window.center()
            window.title = "LilyPond Preview"
            window.contentView = NSHostingView(rootView: AnyView(content))
            window.makeKeyAndOrderFront(nil)
            app.activate(ignoringOtherApps: true)
            app.run()
        } catch {
            fputs("Demo error: \(error)\n", stderr)
            exit(1)
        }
    }
}
#else
@main
struct LPPreviewDemo {
    static func main() {
        print("lp-preview-demo currently supported on macOS only.")
    }
}
#endif

