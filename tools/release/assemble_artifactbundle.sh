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
MAC_ARM=""; MAC_X64=""; LIN_X64=""; LIN_ARM=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version) VER="$2"; shift 2 ;;
    --macos-arm64) MAC_ARM="$2"; shift 2 ;;
    --macos-x86_64) MAC_X64="$2"; shift 2 ;;
    --linux-x86_64) LIN_X64="$2"; shift 2 ;;
    --linux-arm64) LIN_ARM="$2"; shift 2 ;;
    *) echo "Unknown arg: $1"; exit 2 ;;
  esac
done

mkdir -p "$BUNDLE_DIR"

prepare_variant() {
  local triple="$1"; local src="$2"
  mkdir -p "$BUNDLE_DIR/$triple"
  if [[ "$src" =~ \.tar\.gz$ ]] || [[ "$src" =~ ^https?://.*\.tar\.gz$ ]]; then
    echo "Preparing $triple from tarball: $src" >&2
    local tmpdir=$(mktemp -d)
    local tgz="$tmpdir/pkg.tar.gz"
    if [[ "$src" =~ ^https?:// ]]; then curl -L "$src" -o "$tgz"; else cp "$src" "$tgz"; fi
    local top=$(tar -tzf "$tgz" | head -n1 | cut -d/ -f1)
    tar -xzf "$tgz" -C "$tmpdir"
    # Copy the entire package under variant
    rsync -a "$tmpdir/$top/" "$BUNDLE_DIR/$triple/pkg/"
    # Create wrapper
    cat > "$BUNDLE_DIR/$triple/lilypond" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
exec "$HERE/pkg/bin/lilypond" "$@"
EOS
    chmod +x "$BUNDLE_DIR/$triple/lilypond"
  else
    echo "Preparing $triple from executable: $src" >&2
    local tmpfile=$(mktemp)
    if [[ "$src" =~ ^https?:// ]]; then curl -L "$src" -o "$tmpfile"; else cp "$src" "$tmpfile"; fi
    mv "$tmpfile" "$BUNDLE_DIR/$triple/lilypond"
    chmod +x "$BUNDLE_DIR/$triple/lilypond"
  fi
}

if [ -n "$MAC_ARM" ]; then prepare_variant macos-arm64 "$MAC_ARM"; fi
if [ -n "$MAC_X64" ]; then prepare_variant macos-x86_64 "$MAC_X64"; fi
if [ -n "$LIN_X64" ]; then prepare_variant linux-x86_64 "$LIN_X64"; fi
if [ -n "$LIN_ARM" ]; then prepare_variant linux-arm64 "$LIN_ARM"; fi

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
