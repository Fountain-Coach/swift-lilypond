Release Engineering
===================

This repo ships LilyPond via an SPM binary artifact bundle. To produce a release:

1) Choose upstream tag and verify
- Pick the official LilyPond tag from GitLab (e.g., v2.24.1)
- Record details in PROVENANCE.md (tag, commit, environment)

2) Build or obtain per-arch executables
- macOS (arm64, x86_64): use upstream packages or build from source
- Linux (x86_64, arm64): build from source in a clean container

3) Assemble artifact bundle and checksums
- Put executables (or tarballs) into the artifact bundle using the helper script:

  tools/release/assemble_artifactbundle.sh --version v2.24.4 \
    --macos-x86_64 https://gitlab.com/lilypond/lilypond/-/releases/v2.24.4/downloads/lilypond-2.24.4-darwin-x86_64.tar.gz \
    --linux-x86_64 https://gitlab.com/lilypond/lilypond/-/releases/v2.24.4/downloads/lilypond-2.24.4-linux-x86_64.tar.gz

- The script extracts tarballs (if provided), copies the full package under each variant, creates a wrapper executable, updates info.json, zips the bundle, and writes SHA256 checksums to tools/release/checksums.txt

4) Publish release
- Create a GitHub Release for the version
- Attach LilyPondBinaries.artifactbundle.zip and checksums.txt
- Update PROVENANCE.md with final hashes

5) Verification
- Locally: set LILYPOND_PATH to the bundled executable and run `swift test`
- Reproducibility: capture container image digests, timestamps, and exact build commands in PROVENANCE.md

Notes
-----
- We embed the artifact bundle via `path:` in Package.swift. This keeps local dev simple. In future we can switch to `.url` if we host the zip.
- The bundle format supports multiple variants; we currently publish macOS and Linux.
