Provenance for embedded LilyPond binaries
=========================================

This file is maintained by Release Engineering for each release tag.

For every published version:

- Upstream LilyPond tag and URL
- Build environment description (OS, toolchain, dependencies)
- Exact build commands used
- Checksums for produced artifacts (SHA256)
- Reproducibility notes and timestamps
- CVE review for dependencies

Template
--------

- Upstream: https://gitlab.com/lilypond/lilypond/-/releases/tag/vX.Y.Z
- Commit: <SHA>
- Builder: <OS version / Docker image>
- Commands:
  - configure: <args>
  - make: <args>
- Artifacts:
  - macOS arm64: SHA256=<hash>
  - macOS x86_64: SHA256=<hash>
  - Linux x86_64: SHA256=<hash>
- Notes: <reproducible build details>

