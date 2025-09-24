# CONTRIBUTING

Thank you for helping improve **swift-lilypond**!

## Workflow
- **Trunk‑based development** with short‑lived PRs.
- Use **Conventional Commits** (`feat:`, `fix:`, `docs:`, `chore:` …).
- Write tests for new behavior; update docs where applicable.

## Setup
- Xcode 15+ / Swift 6 toolchain (or Swift CLI).
- SwiftPM is the build system of record.

## Testing
- Unit tests for API behavior and diagnostics.
- Golden tests for artifacts (PDF/SVG/PNG/MIDI). Allow minimal, documented nondeterminism.

## Release Process (maintainers)
1. Pick an upstream LilyPond tag from GitLab.
2. Build per‑platform, self‑contained bundles; compute SHA256.
3. Update `Package.swift` `binaryTarget`s and checksums.
4. Update `PROVENANCE.md` with tag, URLs, and checksums.
5. Publish on GitHub Releases; create a Git tag and release notes (pairing `swift-lilypond` → upstream LilyPond).
