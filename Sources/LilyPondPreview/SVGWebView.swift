import Foundation
import SwiftUI

#if canImport(AppKit) && canImport(WebKit)
import WebKit
public struct SVGWebView: NSViewRepresentable {
    private let svgData: Data
    public init(_ data: Data) { self.svgData = data }

    public func makeNSView(context: Context) -> WKWebView { WKWebView() }

    public func updateNSView(_ nsView: WKWebView, context: Context) {
        nsView.load(svgData, mimeType: "image/svg+xml", characterEncodingName: "utf-8", baseURL: URL(fileURLWithPath: "/"))
    }
}
#elseif canImport(UIKit) && canImport(WebKit)
import WebKit
public struct SVGWebView: UIViewRepresentable {
    private let svgData: Data
    public init(_ data: Data) { self.svgData = data }
    public func makeUIView(context: Context) -> WKWebView { WKWebView() }
    public func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.load(svgData, mimeType: "image/svg+xml", characterEncodingName: "utf-8", baseURL: URL(fileURLWithPath: "/"))
    }
}
#else
public struct SVGWebView: View {
    public init(_ data: Data) {}
    public var body: some View { Text("SVG preview not supported on this platform.") }
}
#endif
