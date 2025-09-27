#!/usr/bin/env bash
set -euo pipefail

# Assemble Binaries/LilyPondBinaries.artifactbundle with provided lilypond executables
# Usage:
#   tools/release/assemble_artifactbundle.sh --version v2.24.1 \
#     --macos-arm64 /path/to/lilypond \
#     --macos-x86_64 URL_OR_PATH \
#     --linux-x86_64 URL_OR_PATH \
#     --linux-arm64 URL_OR_PATH

ROOT_DIR=$(cd "$(dirname "$0")/../.." && pwd)
BUNDLE_DIR="$ROOT_DIR/Binaries/LilyPondBinaries.artifactbundle"
INFO_JSON="$BUNDLE_DIR/info.json"
OUT_CHECKSUMS="$ROOT_DIR/tools/release/checksums.txt"

VER="0.0.0-dev"
declare -A INPUTS

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version) VER="$2"; shift 2 ;;
    --macos-arm64) INPUTS[macos-arm64]="$2"; shift 2 ;;
    --macos-x86_64) INPUTS[macos-x86_64]="$2"; shift 2 ;;
    --linux-x86_64) INPUTS[linux-x86_64]="$2"; shift 2 ;;
    --linux-arm64) INPUTS[linux-arm64]="$2"; shift 2 ;;
    *) echo "Unknown arg: $1"; exit 2 ;;
  esac
done

mkdir -p "$BUNDLE_DIR"

fetch_if_url() {
  local src="$1"; local dst="$2"
  if [[ "$src" =~ ^https?:// ]]; then
    echo "Downloading $src ..." >&2
    curl -L "$src" -o "$dst"
    chmod +x "$dst" || true
  else
    cp "$src" "$dst"
    chmod +x "$dst" || true
  fi
}

for triple in "${!INPUTS[@]}"; do
  mkdir -p "$BUNDLE_DIR/$triple"
  tmpfile=$(mktemp)
  fetch_if_url "${INPUTS[$triple]}" "$tmpfile"
  mv "$tmpfile" "$BUNDLE_DIR/$triple/lilypond"
  chmod +x "$BUNDLE_DIR/$triple/lilypond"
done

# Update info.json version field
jq ".artifacts.lilypond.version = \"$VER\"" "$INFO_JSON" > "$INFO_JSON.tmp" && mv "$INFO_JSON.tmp" "$INFO_JSON"

# Compute checksums
rm -f "$OUT_CHECKSUMS"
echo "# LilyPond executables checksums (SHA256)" | tee -a "$OUT_CHECKSUMS"
for f in $(find "$BUNDLE_DIR" -type f -name lilypond | sort); do
  shasum -a 256 "$f" | tee -a "$OUT_CHECKSUMS"
done

echo "# Artifact bundle zip checksum (SHA256)" | tee -a "$OUT_CHECKSUMS"
(cd "$BUNDLE_DIR/.." && zip -r -9 LilyPondBinaries.artifactbundle.zip LilyPondBinaries.artifactbundle >/dev/null)
shasum -a 256 "$BUNDLE_DIR/../LilyPondBinaries.artifactbundle.zip" | tee -a "$OUT_CHECKSUMS"

echo "Wrote checksums to $OUT_CHECKSUMS"

