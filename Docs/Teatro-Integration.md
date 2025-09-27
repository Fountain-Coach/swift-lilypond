Teatro Integration Guide
========================

Goal: use swift-lilypond as a pure Swift wrapper inside Teatro via SPM — no servers, no process/pid management in Teatro aside from calling this library.

1) Add dependency in Teatro/Package.swift

```
.package(url: "https://github.com/Fountain-Coach/swift-lilypond.git", from: "0.1.0")
```

And add the product to a Teatro target that needs rendering:

```
.target(
  name: "TeatroRenderers",
  dependencies: [
    .product(name: "LilyPondKit", package: "swift-lilypond")
  ]
)
```

2) Use the API in Teatro code

```
import LilyPondKit

struct LilyScore: Sendable {
  let content: String
}

extension LilyScore {
  func renderPDF(outDir: URL, base: String = "score") async throws -> [URL] {
    let kit = LilyPond()
    return try await kit.renderToFiles(
      source: content,
      options: .init(format: .pdf),
      outDirectory: outDir,
      baseName: base,
      writeMIDI: true
    )
  }
}
```

This writes `score.pdf` and, if `\\midi {}` exists in the source, `score.midi`.

3) Dev and Release behavior

- Development
  - If you have system `lilypond` in PATH, it will be used automatically.
  - Alternatively, generate and use the local bundle and set `LILYPOND_PATH`:
    - `eval "$(tools/dev/use-local-bundle.sh)"` in this repository before building Teatro.

- Releases
  - Tagged releases of swift-lilypond ship a remote SPM binary artifact bundle; consumers (Teatro) fetch it automatically.
  - No extra process management or server is required; Teatro just calls `LilyPondKit`.

4) Minimal replacement for docs/06_LilyPondMusicRendering.md

Replace the `Process()` example with the snippet above using `LilyPondKit` so Teatro does not shell out to system `lilypond` directly.

