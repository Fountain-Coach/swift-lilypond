import XCTest
@testable import LilyPondKit

final class UnitTests: XCTestCase {
    func testRenderPDF_NoMidi() async throws {
        let runner = MockRunner()
        runner.makePDF = true
        let env = LilyPondEnvironment(runner: runner, locator: MockLocator(url: URL(fileURLWithPath: "/usr/bin/lilypond")))
        let kit = LilyPond(env: env)

        let ly = "\\version \"2.24.0\"\n{ c'4 d' e' f' }"
        let art = try await kit.render(source: ly, options: .init(format: .pdf))
        if case .pdf(let data) = art.visual { XCTAssertGreaterThan(data.count, 0) } else { XCTFail("Expected PDF") }
        XCTAssertNil(art.midi)
        XCTAssertTrue(art.log.contains("LOG"))
    }

    func testRenderSVG_WithMidi_Multipage() async throws {
        let runner = MockRunner()
        runner.makeSVGPages = 0
        // Intentionally out of order names to test natural sort
        runner.extraFiles = [
            "out-10.svg": Data("<svg></svg>".utf8),
            "out-2.svg": Data("<svg></svg>".utf8),
            "out-1.svg": Data("<svg></svg>".utf8)
        ]
        let env = LilyPondEnvironment(runner: runner, locator: MockLocator(url: URL(fileURLWithPath: "/usr/bin/lilypond")))
        let kit = LilyPond(env: env)

        let ly = "\\version \"2.24.0\"\n\\score { { c'4 d' e' f' } \\layout {} \\midi {} }"
        let art = try await kit.render(source: ly, options: .init(format: .svg))
        if case .svg(let pages) = art.visual {
            XCTAssertEqual(pages.count, 3)
        } else { XCTFail("Expected SVG") }
        XCTAssertNotNil(art.midi)
    }

    func testDefaultLocatorHonorsEnvVar() throws {
        setenv("LILYPOND_PATH", "/bin/echo", 1)
        defer { unsetenv("LILYPOND_PATH") }
        let loc = DefaultLocator()
        let url = try loc.find(embeddedPreferred: false, override: nil)
        XCTAssertEqual(url.path, "/bin/echo")
    }

    func testRenderPNG_WithDPI_FlagPassThrough() async throws {
        let runner = MockRunner()
        runner.makePNGPages = 1
        let env = LilyPondEnvironment(runner: runner, locator: MockLocator(url: URL(fileURLWithPath: "/usr/bin/lilypond")))
        let kit = LilyPond(env: env)

        _ = try await kit.render(source: "{ c'1 }", options: .init(format: .png, resolutionDPI: 300))
        let runCall = runner.calls.first(where: { $0.args.contains("--output") })
        let args = runCall?.args ?? []
        XCTAssertTrue(args.contains(where: { $0.contains("-dresolution=300") }), "Expected -dresolution=300 in args: \(args)")
    }

    func testFlags_IncludeAndVerbose_PassThrough() async throws {
        let runner = MockRunner()
        runner.makePDF = true
        let env = LilyPondEnvironment(runner: runner, locator: MockLocator(url: URL(fileURLWithPath: "/usr/bin/lilypond")))
        let kit = LilyPond(env: env)

        _ = try await kit.render(source: "{ c'1 }", options: .init(format: .pdf, includePaths: ["/tmp/includes", "/opt/x"], verbose: true, additionalArgs: ["-ddebug"]))
        let runCall = runner.calls.first(where: { $0.args.contains("--output") })
        let args = runCall?.args ?? []
        XCTAssertTrue(args.contains("-I"))
        XCTAssertTrue(args.contains("/tmp/includes"))
        XCTAssertTrue(args.contains("/opt/x"))
        XCTAssertTrue(args.contains("-V"))
        XCTAssertTrue(args.contains("-ddebug"))
    }

    func testErrorPropagatesOnNonZeroExit() async throws {
        let runner = MockRunner()
        runner.status = 1
        let env = LilyPondEnvironment(runner: runner, locator: MockLocator(url: URL(fileURLWithPath: "/usr/bin/lilypond")))
        let kit = LilyPond(env: env)
        await XCTAssertThrowsErrorAsync(try await kit.render(source: "{ c'1 }"))
    }
}

extension XCTestCase {
    func XCTAssertThrowsErrorAsync<T>(_ expression: @autoclosure () async throws -> T, _ message: String = "", file: StaticString = #file, line: UInt = #line) async {
        do { _ = try await expression(); XCTFail("Expected throw", file: file, line: line) }
        catch { /* OK */ }
    }
}
