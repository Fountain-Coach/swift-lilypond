import Foundation

public struct LilyPondOptions: Sendable {
    public enum VisualFormat: String, Sendable {
        case pdf
        case svg
        case png
    }

    public var format: VisualFormat
    public var resolutionDPI: Int? // for PNG
    public var includePaths: [String]
    public var verbose: Bool
    public var timeoutSeconds: TimeInterval?
    public var additionalArgs: [String]
    public var embeddedBinaryPreferred: Bool

    public init(
        format: VisualFormat = .pdf,
        resolutionDPI: Int? = nil,
        includePaths: [String] = [],
        verbose: Bool = false,
        timeoutSeconds: TimeInterval? = nil,
        additionalArgs: [String] = [],
        embeddedBinaryPreferred: Bool = false
    ) {
        self.format = format
        self.resolutionDPI = resolutionDPI
        self.includePaths = includePaths
        self.verbose = verbose
        self.timeoutSeconds = timeoutSeconds
        self.additionalArgs = additionalArgs
        self.embeddedBinaryPreferred = embeddedBinaryPreferred
    }
}

public struct LilyPondArtifacts: Sendable {
    public enum Visual: Sendable {
        case pdf(Data)
        case svg([Data])
        case png([Data])
    }

    public let visual: Visual
    public let midi: Data?
    public let log: String
    public let version: String?
}

public struct LilyPond: Sendable {
    let env: LilyPondEnvironment

    public init() { self.env = .default }
    internal init(env: LilyPondEnvironment) { self.env = env }

    public func version(lilypondURL override: URL? = nil) throws -> String {
        let bin = try env.locator.find(embeddedPreferred: true, override: override)
        let (out, _) = try env.runner.run(bin.path, args: ["--version"]) // best-effort
        let first = out.split(separator: "\n").first.map(String.init)
        return first ?? out
    }

    public func render(source: String, options: LilyPondOptions = .init()) async throws -> LilyPondArtifacts {
        let work = try FileManager.default.createTemporaryDirectory(prefix: "lpkit-")
        defer { try? FileManager.default.removeItem(at: work) }

        let inputURL = work.appendingPathComponent("score.ly")
        try source.data(using: .utf8)!.write(to: inputURL)

        let outputBase = work.appendingPathComponent("out")
        let bin = try env.locator.find(embeddedPreferred: options.embeddedBinaryPreferred, override: nil)

        var args: [String] = []
        switch options.format {
        case .pdf: args.append("--pdf")
        case .svg: args.append("--svg")
        case .png: args.append("--png")
        }
        if let dpi = options.resolutionDPI, options.format == .png {
            args.append("-dresolution=\(dpi)")
        }
        for inc in options.includePaths { args.append(contentsOf: ["-I", inc]) }
        if options.verbose { args.append("-V") }
        args.append(contentsOf: ["--output", outputBase.path])
        args.append(contentsOf: options.additionalArgs)
        args.append(inputURL.path)

        let (stdout, stderr, terminationStatus) = try env.runner.runWithStatus(bin.path, args: args, timeout: options.timeoutSeconds)
        let log = [stdout, stderr].joined(separator: "\n")
        guard terminationStatus == 0 else {
            throw LilyPondError.processFailed(status: terminationStatus, log: log)
        }

        // Collect outputs
        let fm = FileManager.default
        let outDir = work
        let baseName = outputBase.lastPathComponent

        switch options.format {
        case .pdf:
            let pdfURL = outDir.appendingPathComponent("\(baseName).pdf")
            guard fm.fileExists(atPath: pdfURL.path) else {
                throw LilyPondError.missingOutput("PDF not produced", log: log)
            }
            let pdf = try Data(contentsOf: pdfURL)
            let midi = try? findMIDI(in: outDir)
            let ver = try? version(lilypondURL: bin)
            return LilyPondArtifacts(visual: .pdf(pdf), midi: midi, log: log, version: ver)
        case .svg:
            // Gather all SVG pages
            let svgs = try collectMultipageArtifacts(in: outDir, base: baseName, ext: "svg")
            guard !svgs.isEmpty else { throw LilyPondError.missingOutput("SVG not produced", log: log) }
            let midi = try? findMIDI(in: outDir)
            let ver = try? version(lilypondURL: bin)
            return LilyPondArtifacts(visual: .svg(svgs), midi: midi, log: log, version: ver)
        case .png:
            let pngs = try collectMultipageArtifacts(in: outDir, base: baseName, ext: "png")
            guard !pngs.isEmpty else { throw LilyPondError.missingOutput("PNG not produced", log: log) }
            let midi = try? findMIDI(in: outDir)
            let ver = try? version(lilypondURL: bin)
            return LilyPondArtifacts(visual: .png(pngs), midi: midi, log: log, version: ver)
        }
    }

    private func collectMultipageArtifacts(in dir: URL, base: String, ext: String) throws -> [Data] {
        let fm = FileManager.default
        let contents = try fm.contentsOfDirectory(atPath: dir.path)
        // Accept common naming patterns: out.svg, out-1.svg, out-page1.svg
        let candidates = contents.filter { name in
            name.hasSuffix(".\(ext)") && (name == "\(base).\(ext)" || name.hasPrefix("\(base)-") || name.hasPrefix("\(base)-page"))
        }
        let sorted = candidates.sorted(by: naturalOrder)
        return try sorted.map { name in
            let url = dir.appendingPathComponent(name)
            return try Data(contentsOf: url)
        }
    }

    private func findMIDI(in dir: URL) throws -> Data? {
        let fm = FileManager.default
        let contents = try fm.contentsOfDirectory(atPath: dir.path)
        if let midiName = contents.first(where: { $0.lowercased().hasSuffix(".midi") || $0.lowercased().hasSuffix(".mid") }) {
            return try Data(contentsOf: dir.appendingPathComponent(midiName))
        }
        return nil
    }
}

// MARK: - Helpers

enum LilyPondError: Error, CustomStringConvertible {
    case notFound(String)
    case processFailed(status: Int32, log: String)
    case missingOutput(String, log: String)

    var description: String {
        switch self {
        case .notFound(let m): return "LilyPond not found: \(m)"
        case .processFailed(let status, _): return "LilyPond failed with status \(status)"
        case .missingOutput(let m, _): return m
        }
    }
}

enum LilyPondLocator {
    static func find(embeddedPreferred: Bool, override: URL?) throws -> URL {
        if let override = override { return override }

        if embeddedPreferred {
            if let url = Embedded.binaryURL() { return url }
        }

        if let envPath = ProcessInfo.processInfo.environment["LILYPOND_PATH"], !envPath.isEmpty {
            let url = URL(fileURLWithPath: envPath)
            if FileManager.default.isExecutableFile(atPath: url.path) { return url }
        }

        if let which = try? ProcessExecutor.run("/usr/bin/which", args: ["lilypond"]).0, !which.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return URL(fileURLWithPath: which.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        throw LilyPondError.notFound("No embedded binary and no system lilypond in PATH.")
    }

    enum Embedded {
        static func binaryURL() -> URL? {
            // Prefer a path generated by the build plugin (from the artifact bundle)
            #if SWIFT_PACKAGE
            if !LilyPondEmbedded.toolPath.isEmpty {
                let url = URL(fileURLWithPath: LilyPondEmbedded.toolPath)
                if FileManager.default.isExecutableFile(atPath: url.path) { return url }
            }
            #endif
            // As a fallback, check for a resource named "lilypond" bundled (dev only)
            #if SWIFT_PACKAGE
            if let url = Bundle.module.url(forResource: "lilypond", withExtension: nil),
               FileManager.default.isExecutableFile(atPath: url.path) {
                return url
            }
            #endif
            return nil
        }
    }
}

enum ProcessExecutor {
    @discardableResult
    static func run(_ launchPath: String, args: [String]) throws -> (String, String) {
        let (out, err, _) = try runWithStatus(launchPath, args: args, timeout: nil)
        return (out, err)
    }

    static func runWithStatus(_ launchPath: String, args: [String], timeout: TimeInterval?) throws -> (String, String, Int32) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: launchPath)
        process.arguments = args

        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe

        try process.run()

        if let timeout = timeout {
            let deadline = DispatchTime.now() + timeout
            let group = DispatchGroup()
            group.enter()
            DispatchQueue.global().async {
                process.waitUntilExit()
                group.leave()
            }
            if group.wait(timeout: deadline) == .timedOut {
                process.terminate()
            }
        } else {
            process.waitUntilExit()
        }

        let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
        let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
        let out = String(data: outData, encoding: .utf8) ?? ""
        let err = String(data: errData, encoding: .utf8) ?? ""
        return (out, err, process.terminationStatus)
    }
}

// MARK: - Testable environment

protocol ProcessRunning: Sendable {
    @discardableResult
    func run(_ launchPath: String, args: [String]) throws -> (String, String)
    func runWithStatus(_ launchPath: String, args: [String], timeout: TimeInterval?) throws -> (String, String, Int32)
}

protocol LilyPondLocating: Sendable {
    func find(embeddedPreferred: Bool, override: URL?) throws -> URL
}

struct LilyPondEnvironment: Sendable {
    var runner: ProcessRunning
    var locator: LilyPondLocating

    static let `default` = LilyPondEnvironment(runner: DefaultRunner(), locator: DefaultLocator())
}

struct DefaultRunner: ProcessRunning {
    func run(_ launchPath: String, args: [String]) throws -> (String, String) {
        try ProcessExecutor.run(launchPath, args: args)
    }
    func runWithStatus(_ launchPath: String, args: [String], timeout: TimeInterval?) throws -> (String, String, Int32) {
        try ProcessExecutor.runWithStatus(launchPath, args: args, timeout: timeout)
    }
}

struct DefaultLocator: LilyPondLocating {
    func find(embeddedPreferred: Bool, override: URL?) throws -> URL {
        try LilyPondLocator.find(embeddedPreferred: embeddedPreferred, override: override)
    }
}

extension FileManager {
    func createTemporaryDirectory(prefix: String) throws -> URL {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent(prefix + UUID().uuidString, isDirectory: true)
        try createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
        return dir
    }
}

// Natural order sort helper for page suffixes
private func naturalOrder(_ a: String, _ b: String) -> Bool {
    func key(_ s: String) -> (String, Int) {
        let name = URL(fileURLWithPath: s).deletingPathExtension().lastPathComponent
        let digits = name.reversed().prefix { $0.isNumber }.reversed()
        let number = Int(String(digits)) ?? 0
        return (s, number)
    }
    let ka = key(a), kb = key(b)
    if ka.1 == kb.1 { return ka.0 < kb.0 }
    return ka.1 < kb.1
}
