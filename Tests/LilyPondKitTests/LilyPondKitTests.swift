import XCTest
@testable import LilyPondKit

final class LilyPondKitTests: XCTestCase {
    func testRenderPDFIfLilyPondAvailable() async throws {
        // Check for system lilypond
        let which = try? ProcessExecutor.run("/usr/bin/which", args: ["lilypond"]).0
        let hasLP = (which?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
        if !hasLP {
            throw XCTSkip("lilypond not installed; skipping integration test")
        }

        let ly = [
            "\\version \"2.24.0\"",
            "{ c'4 d' e' f' }"
        ].joined(separator: "\n")

        let kit = LilyPond()
        let art = try await kit.render(source: ly, options: .init(format: .pdf, verbose: true))
        switch art.visual {
        case .pdf(let data):
            XCTAssertGreaterThan(data.count, 100, "Expected non-empty PDF")
        default:
            XCTFail("Expected PDF output")
        }
    }
}

