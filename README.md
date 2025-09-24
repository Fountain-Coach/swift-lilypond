# swift-lilypond

A drop‑in **Swift Package** that wraps **LilyPond** to render **PDF/SVG/PNG** and **MIDI** — designed for the Fountain‑Coach Swift family.

- **No external installs for consumers**: LilyPond is embedded via SPM `binaryTarget`s.
- **Ergonomic Swift API** (async/await), structured diagnostics, sandboxed runs.
- **MIDI supported** via LilyPond’s native `\midi {}` block (inside `\score { ... }`).
- **Aligned with official upstream on GitLab** (canonical): <https://gitlab.com/lilypond/lilypond/-/releases>.

> LilyPond remains the authoritative engraver; this package orchestrates it predictably and safely.

---

## Status & Scope

- **Outputs:** PDF, SVG, PNG, and (optionally) MIDI (when your score includes a `\midi {}` block).
- **Upstream alignment:** We pin to LilyPond tags from GitLab and record provenance (exact tag + checksums).
- **Non‑goals:** Audio rendering. MIDI → audio belongs in sibling packages such as **`swift-csound`**.

---

## Quick Start

Add the dependency to your `Package.swift`:

```swift
.package(url: "https://github.com/Fountain-Coach/swift-lilypond.git", from: "0.1.0")
```

Basic usage:

```swift
import LilyPondKit

let ly = [
  "\\version \"2.24.0\"",
  "\\score {",
  "  \\new Staff \\with { midiInstrument = \"glockenspiel\" }",
  "  { c'4 d' e' f' | g'1 }",
  "  \\layout {}",
  "  \\midi { \\tempo 4 = 96 }",
  "}"
].joined(separator: "\n")

let kit = LilyPond()
let art = try await kit.render(source: ly)
// art.visualData  -> PDF/SVG/PNG (default PDF)
// art.midiData    -> MIDI if \midi{} present
```

To render **SVG** or **PNG**, set the option accordingly; SVG uses a dedicated backend and should be rendered in a separate run.

---

## Design Principles

- **Hermetic runtime**: embedded binaries, fonts/configs, and environment bootstrap for consistent results.
- **Provenance**: every release documents upstream tag, checksums, and build recipe (`PROVENANCE.md`).
- **Safety**: strict artifact verification before publishing.
- **Clarity**: small Swift API, thorough README and troubleshooting.

---

## MIDI Notes

LilyPond only writes a MIDI file **if a `\midi {}` block appears inside a `\score { ... }`**. Tempo can be set by `\tempo` or via properties in the `\midi` block (e.g., `tempoWholesPerMinute`) without printing a metronome mark in the score.

Instrument program selection is controlled via `midiInstrument` on staves; channel mapping follows LilyPond’s standard rules.

---

## Official Upstream

- **Canonical project**: <https://gitlab.com/lilypond/lilypond>
- **Releases hub**: <https://gitlab.com/lilypond/lilypond/-/releases>
- **Development overview**: <https://lilypond.org/development>

We avoid GitHub mirrors for release artifacts and always cite the GitLab tag used.

---

## Roadmap

- Live log streaming (via `AsyncStream`) during engraving
- Richer diagnostics (filename:line:column)
- Golden tests across platforms for PDF/SVG/PNG/MIDI
- SwiftUI demo views for PDF/SVG preview

---

## Licensing

- **LilyPond** is **GPL**. Embedding it as a binary artifact requires:
  - Shipping GPL text and notices
  - Providing a **source‑offer** to the exact LilyPond sources used
- Fonts/configs carry their own licenses (documented in `LICENSES/`).

---

## Sibling Repos & Interop

- **`swift-csound`** (MIDI → audio rendering) — keep repo boundaries clean; this package exports MIDI only.
- Other Fountain‑Coach Swift repos share conventions: semver, provenance, AGENTS, CI parity.

---

## Contributing

See **CONTRIBUTING.md** for branching, commit style, CI, and release steps.
