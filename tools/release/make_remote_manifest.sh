#!/usr/bin/env bash
set -euo pipefail

# Generate Package.swift.remote using a remote binaryTarget URL + checksum.
# Inputs:
#   --url <asset_url>
#   --checksum <sha256>
# Writes Package.swift.remote next to Package.swift

ROOT_DIR=$(cd "$(dirname "$0")/../.." && pwd)
PKG="$ROOT_DIR/Package.swift"
OUT="$ROOT_DIR/Package.swift.remote"

URL=""; SUM=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --url) URL="$2"; shift 2 ;;
    --checksum) SUM="$2"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "$URL" || -z "$SUM" ]]; then
  echo "Usage: $0 --url <asset_url> --checksum <sha256>" >&2
  exit 2
fi

awk -v url="$URL" -v sum="$SUM" '
  BEGIN{ repl=0 }
  /\.binaryTarget\(/ && /LilyPondBinaries/ && /path:/ {
    print "        .binaryTarget(\n            name: \"LilyPondBinaries\",\n            url: \"" url "\",\n            checksum: \"" sum "\"\n        ),";
    # skip until closing paren of this block
    repl=1; next
  }
  { if(repl==0) print $0 }
' "$PKG" > "$OUT"

echo "Wrote $OUT"

