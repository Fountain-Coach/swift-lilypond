import XCTest
@testable import LilyPondKit

final class GoldenTests: XCTestCase {
    func testGolden_V2244_PDF_SVG_MIDI() async throws {
        let goldenRoot = URL(fileURLWithPath: "Tests/Golden/expected/v2.24.4")
        let scorePath = "Tests/Golden/scores/simple.ly"
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: goldenRoot.path, isDirectory: &isDir), isDir.boolValue else {
            throw XCTSkip("Golden corpus not present; run tools/golden/build_golden.sh to generate.")
        }

        // Skip if lilypond not available
        let which = try? ProcessExecutor.run("/usr/bin/which", args: ["lilypond"]).0
        let envPath = ProcessInfo.processInfo.environment["LILYPOND_PATH"]
        let hasLP = (envPath?.isEmpty == false) || (which?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
        if !hasLP { throw XCTSkip("lilypond not installed; skipping golden test") }

        let ly = try String(contentsOfFile: scorePath, encoding: .utf8)
        let kit = LilyPond()
        // PDF
        let pdfArt = try await kit.render(source: ly, options: .init(format: .pdf))
        if case .pdf(let data) = pdfArt.visual {
            let expected = try Data(contentsOf: goldenRoot.appendingPathComponent("simple.pdf"))
            XCTAssertEqual(sha256(data), sha256(expected), "PDF checksum mismatch")
        } else { XCTFail("Expected PDF output") }
        // SVG first page compare checksum if exists
        let svgDir = goldenRoot.appendingPathComponent("svg")
        if FileManager.default.fileExists(atPath: svgDir.path, isDirectory: &isDir), isDir.boolValue {
            let svgArt = try await kit.render(source: ly, options: .init(format: .svg))
            if case .svg(let pages) = svgArt.visual, let first = pages.first {
                let expected = try Data(contentsOf: svgDir.appendingPathComponent("page-1.svg"))
                XCTAssertEqual(sha256(first), sha256(expected), "SVG checksum mismatch (page 1)")
            }
        }
        // MIDI compare checksum if exists
        let midiPath = goldenRoot.appendingPathComponent("simple.midi").path
        if FileManager.default.fileExists(atPath: midiPath) {
            var midiData: Data? = pdfArt.midi
            if midiData == nil {
                let rerun = try? await kit.render(source: ly, options: .init(format: .pdf))
                midiData = rerun?.midi
            }
            if let midi = midiData {
                let expected = try Data(contentsOf: URL(fileURLWithPath: midiPath))
                XCTAssertEqual(sha256(midi), sha256(expected), "MIDI checksum mismatch")
            }
        }
    }
}

private func sha256(_ data: Data) -> String {
    // FNV-1a 64-bit as a simple deterministic hash for equality checks
    return String(data.reduce(into: UInt64(1469598103934665603)) { (h, b) in h = (h ^ UInt64(b)) &* 1099511628211 }, radix: 16)
}
