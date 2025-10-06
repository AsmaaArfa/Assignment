#!/usr/bin/env zsh
# Render Mermaid diagram to a high-resolution PNG suitable for slides
# Usage: ./diagrams/render_for_slides.sh [input.mmd] [output.png]
# Defaults: diagrams/ads_er_diagram.mmd -> diagrams/ads_er_diagram_slide.png

set -euo pipefail

INPUT=${1:-diagrams/ads_er_diagram.mmd}
OUT_PNG=${2:-diagrams/ads_er_diagram_slide.png}
OUT_SVG=${OUT_PNG:r}_rendered.svg

# Recommended high-res size for slides (1920x1080 or 3840x2160 for 2x DPI)
WIDTH=3840
HEIGHT=2160
SCALE=2
BG=white

# Use npx so users don't need a global install
echo "Rendering $INPUT -> $OUT_PNG (PNG) and $OUT_SVG (SVG)"

# Render SVG first (vector)
npx @mermaid-js/mermaid-cli -i "$INPUT" -o "$OUT_SVG" -w $WIDTH -H $HEIGHT -b $BG || {
  echo "SVG render failed" >&2
  exit 1
}

# Render PNG (raster) with scale; mmdc supports --scale for raster output
npx @mermaid-js/mermaid-cli -i "$INPUT" -o "$OUT_PNG" -w $WIDTH -H $HEIGHT -b $BG --scale $SCALE || {
  echo "PNG render failed" >&2
  exit 1
}

echo "Rendered files:"
echo "  - $OUT_SVG"
echo "  - $OUT_PNG"

echo "Tip: adjust WIDTH/HEIGHT/scale in this script to control DPI and aspect ratio."