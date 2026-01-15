#
#  update_flags.sh
#  CircleFlagsKit
#
#

#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENDOR_DIR="$ROOT_DIR/Vendor/circle-flags"
OUT_DIR="$ROOT_DIR/Sources/CircleFlagsKit/Resources"

SIZE="${1:-128}"   # Default: 128 (can pass 96 / 256, etc.)
echo "==> Output size: ${SIZE}x${SIZE}"

mkdir -p "$OUT_DIR"

echo "==> Updating submodule..."
git submodule update --init --recursive

# Do NOT pull inside the submodule (this would bypass the pinned version)
# To update upstream, use: git submodule update --remote --merge
# Therefore we intentionally remove `pull` here for stability and reproducibility
# git -C "$VENDOR_DIR" pull --rebase || true

# Verified: SVGs are located in the `flags` directory
SVG_DIR="$VENDOR_DIR/flags"
if [ ! -d "$SVG_DIR" ]; then
  echo "ERROR: SVG directory not found: $SVG_DIR"
  exit 1
fi

echo "==> Using SVG directory: $SVG_DIR"

# Choose converter: prefer rsvg-convert (fast, stable), fallback to inkscape
CONVERTER=""
if command -v rsvg-convert >/dev/null 2>&1; then
  CONVERTER="rsvg"
elif command -v inkscape >/dev/null 2>&1; then
  CONVERTER="inkscape"
else
  echo "ERROR: Need rsvg-convert or inkscape installed."
  echo "macOS (Homebrew): brew install librsvg   (provides rsvg-convert)"
  echo "or: brew install inkscape"
  exit 1
fi

echo "==> Converter: $CONVERTER"

echo "==> Cleaning old PNGs in Resources..."
find "$OUT_DIR" -maxdepth 1 -type f -name "*.png" -delete

echo "==> Converting SVGs (ISO alpha-2 only: xx.svg)..."
count=0
skipped=0

for svg in "$SVG_DIR"/*.svg; do
  base="$(basename "$svg")"
  code="${base%.svg}"
  code="$(echo "$code" | tr '[:upper:]' '[:lower:]')"

  # Filter out region codes like it-23 / es-ib
  # Keep only two-letter country codes
  if [[ ! "$code" =~ ^[a-z]{2}$ ]]; then
    skipped=$((skipped+1))
    continue
  fi

  out="$OUT_DIR/${code}.png"

  if [ "$CONVERTER" = "rsvg" ]; then
    rsvg-convert -w "$SIZE" -h "$SIZE" "$svg" -o "$out"
  else
    inkscape "$svg" --export-type=png --export-filename="$out" -w "$SIZE" -h "$SIZE" >/dev/null
  fi

  count=$((count+1))
done

echo "==> Done. Generated $count PNG files into:"
echo "    $OUT_DIR"
echo "==> Skipped (non-alpha2): $skipped"
echo "==> Tip: run 'swift test' to verify resources load."
