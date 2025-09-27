#!/usr/bin/env bash
set -euo pipefail

# Emits an export line to set LILYPOND_PATH to your local artifact bundle wrapper.
# Usage (set in current shell):
#   eval "$(tools/dev/use-local-bundle.sh)"

ROOT_DIR=$(cd "$(dirname "$0")/../.." && pwd)
BUNDLE="$ROOT_DIR/Binaries/LilyPondBinaries.artifactbundle"

OS=$(uname -s)
ARCH=$(uname -m)

candidate=""
case "$OS" in
  Darwin)
    candidate="$BUNDLE/macos-x86_64/lilypond"
    ;;
  Linux)
    candidate="$BUNDLE/linux-x86_64/lilypond"
    ;;
  *)
    ;;
esac

if [[ -z "$candidate" || ! -x "$candidate" ]]; then
  echo "# ERROR: Local lilypond wrapper not found at $candidate" 1>&2
  echo "# Generate the local bundle first:" 1>&2
  echo "# tools/release/assemble_artifactbundle.sh --version v2.24.4 \\" 1>&2
  echo "#   --macos-x86_64 https://gitlab.com/lilypond/lilypond/-/releases/v2.24.4/downloads/lilypond-2.24.4-darwin-x86_64.tar.gz \\" 1>&2
  echo "#   --linux-x86_64 https://gitlab.com/lilypond/lilypond/-/releases/v2.24.4/downloads/lilypond-2.24.4-linux-x86_64.tar.gz" 1>&2
  exit 1
fi

echo "export LILYPOND_PATH=\"$candidate\""

