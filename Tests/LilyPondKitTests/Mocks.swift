import Foundation
@testable import LilyPondKit

final class MockRunner: ProcessRunning, @unchecked Sendable {
    struct RunCall { let launchPath: String; let args: [String] }
    var calls: [RunCall] = []
    var status: Int32 = 0
    var stdout: String = "LOG: ok"
    var stderr: String = ""

    // Configure outputs for format
    var makePDF: Bool = true
    var makeSVGPages: Int = 0
    var makePNGPages: Int = 0
    var writeMIDIIfPresent: Bool = true
    var extraFiles: [String: Data] = [:] // relative to output dir

    @discardableResult
    func run(_ launchPath: String, args: [String]) throws -> (String, String) {
        calls.append(.init(launchPath: launchPath, args: args))
        return (stdout, stderr)
    }

    func runWithStatus(_ launchPath: String, args: [String], timeout: TimeInterval?) throws -> (String, String, Int32) {
        calls.append(.init(launchPath: launchPath, args: args))

        // Simulate lilypond by writing files indicated by args
        var outBase: String?
        var format: String = "pdf"
        var inputPath: String?
        var dpi: String?
        var idx = 0
        while idx < args.count {
            let a = args[idx]
            if a == "--output" { outBase = args[idx+1]; idx += 2; continue }
            if a == "--pdf" { format = "pdf" }
            if a == "--svg" { format = "svg" }
            if a == "--png" { format = "png" }
            if a.hasPrefix("-dresolution=") { dpi = a }
            idx += 1
        }
        inputPath = args.last

        if let outBase = outBase {
            let outDir = URL(fileURLWithPath: outBase).deletingLastPathComponent()
            let baseName = URL(fileURLWithPath: outBase).lastPathComponent
            try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)
            switch format {
            case "pdf":
                if makePDF {
                    let pdfURL = outDir.appendingPathComponent("\(baseName).pdf")
                    try Data("%PDF-1.4\n".utf8).write(to: pdfURL)
                }
            case "svg":
                let pages = max(makeSVGPages, 1)
                for p in 1...pages {
                    let svgURL = outDir.appendingPathComponent("\(baseName)-\(p).svg")
                    try Data("<svg></svg>".utf8).write(to: svgURL)
                }
            case "png":
                let pages = max(makePNGPages, 1)
                for p in 1...pages {
                    let pngURL = outDir.appendingPathComponent("\(baseName)-\(p).png")
                    try Data([0x89, 0x50, 0x4E, 0x47]).write(to: pngURL)
                }
            default: break
            }
            // Write extra files
            for (rel, data) in extraFiles {
                let url = outDir.appendingPathComponent(rel)
                try data.write(to: url)
            }
            if writeMIDIIfPresent, let inputPath {
                if let s = try? String(contentsOfFile: inputPath), s.contains("\\midi") {
                    let midiURL = outDir.appendingPathComponent("\(baseName).midi")
                    try Data("MThd".utf8).write(to: midiURL)
                }
            }
        }

        _ = dpi // touch
        return (stdout, stderr, status)
    }
}

struct MockLocator: LilyPondLocating {
    var url: URL
    func find(embeddedPreferred: Bool, override: URL?) throws -> URL { override ?? url }
}
