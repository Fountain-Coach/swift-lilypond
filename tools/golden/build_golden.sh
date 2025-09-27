#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/../.." && pwd)
SCORE="$ROOT_DIR/Tests/Golden/scores/simple.ly"
OUT_DIR="$ROOT_DIR/Tests/Golden/expected/v2.24.4"
mkdir -p "$OUT_DIR"

export SWIFT_BUILD_FLAGS=${SWIFT_BUILD_FLAGS:-}

ensure_lilypond() {
  if command -v lilypond >/dev/null 2>&1; then
    echo "Using system lilypond: $(command -v lilypond)" >&2
    return 0
  fi
  echo "No system lilypond; downloading v2.24.4 generic package..." >&2
  TMP=$(mktemp -d)
  URL=https://gitlab.com/lilypond/lilypond/-/releases/v2.24.4/downloads/lilypond-2.24.4-$(uname | tr '[:upper:]' '[:lower:]')-x86_64.tar.gz
  curl -L "$URL" -o "$TMP/lp.tar.gz"
  tar -xzf "$TMP/lp.tar.gz" -C "$TMP"
  TOP=$(tar -tzf "$TMP/lp.tar.gz" | head -n1 | cut -d/ -f1)
  export LILYPOND_PATH="$TMP/$TOP/bin/lilypond"
  echo "Using downloaded lilypond: $LILYPOND_PATH" >&2
}

ensure_lilypond

echo "Rendering PDF..." >&2
swift run $SWIFT_BUILD_FLAGS lpkit --format pdf --input "$SCORE" --output "$OUT_DIR/simple.pdf"
echo "Rendering SVG..." >&2
mkdir -p "$OUT_DIR/svg"
swift run $SWIFT_BUILD_FLAGS lpkit --format svg --input "$SCORE" --output "$OUT_DIR/svg"
echo "Rendering MIDI..." >&2
swift run $SWIFT_BUILD_FLAGS lpkit --format pdf --input "$SCORE" --midi "$OUT_DIR/simple.midi" --output "$OUT_DIR/simple.pdf" >/dev/null 2>&1 || true

echo "Computing checksums..." >&2
(cd "$OUT_DIR" && shasum -a 256 simple.pdf > checksums.txt)
if [ -f "$OUT_DIR/simple.midi" ]; then (cd "$OUT_DIR" && shasum -a 256 simple.midi >> checksums.txt); fi
if [ -d "$OUT_DIR/svg" ]; then (cd "$OUT_DIR/svg" && shasum -a 256 *.svg > ../checksums-svg.txt); fi

echo "Done. Goldens in $OUT_DIR" >&2

