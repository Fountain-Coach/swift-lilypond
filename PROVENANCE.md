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

Release v2.24.4
----------------

- Upstream: https://gitlab.com/lilypond/lilypond/-/releases/v2.24.4
- Builder: macOS 14 runner
- Inputs:
  - macOS x86_64 tarball: lilypond-2.24.4-darwin-x86_64.tar.gz
  - Linux x86_64 tarball: lilypond-2.24.4-linux-x86_64.tar.gz
- Packaging:
  - Embedded full upstream package under each variant at `pkg/`
  - Wrapper executable `lilypond` calls `pkg/bin/lilypond`
- Checksums (SHA256):
  - Bundle zip: 44b655f2f0f07ef8833210d79173d84efbce05e1b0d578afbdafdb1782b12757
  - macOS x86_64 wrapper: fa907d2d956751c8cfb539818edfe24eb1fdd68009d1ddd09992c9dafb03b4b1
  - macOS x86_64 upstream bin: 204e6b5414ea1c8eb77a004128c6231b1a23ac2b0ebbc72281ecbcc8aaf3f169
  - Linux x86_64 wrapper: fa907d2d956751c8cfb539818edfe24eb1fdd68009d1ddd09992c9dafb03b4b1
  - Linux x86_64 upstream bin: d54351796cf4284d355b6d3c8669ae5352c4d89238ba866d7f1a9e7f419344ce
- Notes:
  - macOS arm64 and Linux arm64 variants remain stubs; we plan to supply native builds as upstream provides them.
  - For reproducibility, obtain tarballs from the upstream release URL and re-run `tools/release/assemble_artifactbundle.sh`.

