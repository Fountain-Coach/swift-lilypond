import Foundation
import LilyPondKit

struct CLIError: Error, CustomStringConvertible {
    let description: String
}

enum Format: String { case pdf, svg, png }

@main
struct LPKitCLI {
    static func main() async {
        do {
            let args = CommandLine.arguments.dropFirst()
            var format: Format = .pdf
            var inputPath: String? = nil
            var outputPath: String? = nil
            var midiPath: String? = nil
            var verbose = false
            var includePaths: [String] = []
            var dpi: Int? = nil

            var it = args.makeIterator()
            while let a = it.next() {
                switch a {
                case "--format":
                    guard let v = it.next(), let f = Format(rawValue: v) else { throw CLIError(description: "--format requires pdf|svg|png") }
                    format = f
                case "--input":
                    inputPath = it.next()
                case "--output":
                    outputPath = it.next()
                case "--midi":
                    midiPath = it.next()
                case "-I":
                    if let p = it.next() { includePaths.append(p) }
                case "--dpi":
                    if let v = it.next(), let n = Int(v) { dpi = n }
                case "-v", "--verbose":
                    verbose = true
                case "-h", "--help":
                    printUsage()
                    return
                default:
                    if inputPath == nil { inputPath = a } else { throw CLIError(description: "Unexpected argument: \(a)") }
                }
            }

            let source: String
            if let p = inputPath {
                source = try String(contentsOfFile: p, encoding: .utf8)
            } else {
                // Read stdin
                let data = FileHandle.standardInput.readDataToEndOfFile()
                source = String(data: data, encoding: .utf8) ?? ""
            }
            if source.isEmpty { throw CLIError(description: "No input provided") }

            let opt = LilyPondOptions(
                format: .init(rawValue: format.rawValue) ?? .pdf,
                resolutionDPI: dpi,
                includePaths: includePaths,
                verbose: verbose
            )

            let kit = LilyPond()
            let art = try await kit.render(source: source, options: opt)

            switch art.visual {
            case .pdf(let data):
                if let out = outputPath {
                    try data.write(to: URL(fileURLWithPath: out))
                } else {
                    FileHandle.standardOutput.write(data)
                }
            case .svg(let pages):
                if let out = outputPath {
                    // If output is a directory, write pages as out-1.svg, etc.
                    var isDir: ObjCBool = false
                    if FileManager.default.fileExists(atPath: out, isDirectory: &isDir), isDir.boolValue {
                        for (idx, page) in pages.enumerated() {
                            let p = URL(fileURLWithPath: out).appendingPathComponent("page-\(idx+1).svg")
                            try page.write(to: p)
                        }
                    } else {
                        // Single file or first page only
                        try pages.first?.write(to: URL(fileURLWithPath: out))
                    }
                } else {
                    // Write first page to stdout
                    if let first = pages.first { FileHandle.standardOutput.write(first) }
                }
            case .png(let pages):
                if let out = outputPath {
                    var isDir: ObjCBool = false
                    if FileManager.default.fileExists(atPath: out, isDirectory: &isDir), isDir.boolValue {
                        for (idx, page) in pages.enumerated() {
                            let p = URL(fileURLWithPath: out).appendingPathComponent("page-\(idx+1).png")
                            try page.write(to: p)
                        }
                    } else {
                        try pages.first?.write(to: URL(fileURLWithPath: out))
                    }
                } else {
                    if let first = pages.first { FileHandle.standardOutput.write(first) }
                }
            }

            if let midi = art.midi {
                if let mp = midiPath {
                    try midi.write(to: URL(fileURLWithPath: mp))
                }
            }

            if verbose {
                FileHandle.standardError.write(Data(("\n--- LilyPond Log ---\n" + art.log).utf8))
            }
        } catch let e as CLIError {
            fputs("Error: \(e.description)\n", stderr)
            printUsage()
            exit(2)
        } catch {
            fputs("Error: \(error)\n", stderr)
            exit(1)
        }
    }

    static func printUsage() {
        print("""
        Usage: lpkit [--format pdf|svg|png] [--input path.ly] [--output out] [--midi midi.mid] [-I includePath] [--dpi 300] [-v]

        If --input is omitted, reads from stdin. For SVG/PNG with multiple pages, use --output as a directory to write page-*.svg/png files.
        """)
    }
}

