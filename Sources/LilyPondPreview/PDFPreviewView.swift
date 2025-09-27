import Foundation
import SwiftUI

#if canImport(AppKit) && canImport(PDFKit)
import PDFKit

public struct PDFPreviewView: NSViewRepresentable {
    private let data: Data

    public init(_ data: Data) { self.data = data }

    public func makeNSView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        return view
    }

    public func updateNSView(_ nsView: PDFView, context: Context) {
        nsView.document = PDFDocument(data: data)
    }
}
#elseif canImport(UIKit) && canImport(PDFKit)
import PDFKit

public struct PDFPreviewView: UIViewRepresentable {
    private let data: Data
    public init(_ data: Data) { self.data = data }
    public func makeUIView(context: Context) -> PDFView { PDFView() }
    public func updateUIView(_ uiView: PDFView, context: Context) { uiView.document = PDFDocument(data: data) }
}
#else
public struct PDFPreviewView: View {
    public init(_ data: Data) {}
    public var body: some View { Text("PDF preview not supported on this platform.") }
}
#endif
