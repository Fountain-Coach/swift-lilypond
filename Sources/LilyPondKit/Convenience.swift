import Foundation

public extension LilyPond {
    /// Renders the given LilyPond source and writes artifacts to the filesystem.
    /// - Parameters:
    ///   - source: LilyPond source text.
    ///   - options: Output options (format, dpi, etc.).
    ///   - outDirectory: Destination directory (created if missing).
    ///   - baseName: Base filename without extension (e.g., "score").
    ///   - writeMIDI: If MIDI exists, write `<baseName>.midi` alongside visual output.
    /// - Returns: Paths of written files.
    @discardableResult
    func renderToFiles(
        source: String,
        options: LilyPondOptions = .init(),
        outDirectory: URL,
        baseName: String = "score",
        writeMIDI: Bool = true
    ) async throws -> [URL] {
        try FileManager.default.createDirectory(at: outDirectory, withIntermediateDirectories: true)
        let art = try await render(source: source, options: options)
        var written: [URL] = []
        switch art.visual {
        case .pdf(let data):
            let url = outDirectory.appendingPathComponent("\(baseName).pdf")
            try data.write(to: url)
            written.append(url)
        case .svg(let pages):
            for (idx, page) in pages.enumerated() {
                let url = outDirectory.appendingPathComponent("\(baseName)-\(idx+1).svg")
                try page.write(to: url)
                written.append(url)
            }
        case .png(let pages):
            for (idx, page) in pages.enumerated() {
                let url = outDirectory.appendingPathComponent("\(baseName)-\(idx+1).png")
                try page.write(to: url)
                written.append(url)
            }
        }
        if writeMIDI, let midi = art.midi {
            let url = outDirectory.appendingPathComponent("\(baseName).midi")
            try midi.write(to: url)
            written.append(url)
        }
        return written
    }
}

