#!/usr/bin/env bash
# Converts every .jpg/.jpeg/.png in a folder to WebP, keeping each file's name:
#   "DiscosGranja 45-501.jpg"  →  "DiscosGranja 45-501.webp"
#
# - Only shrinks: images whose longest side is above MAX_SIDE are scaled down to it;
#   smaller images keep their original size (never upscaled).
# - The originals are never modified, and nothing in the output folder is deleted
#   (an existing .webp with the same name is overwritten).
# - Only the top level of the source folder is processed (no subfolders).
#
# Requirements (macOS): cwebp (brew install webp) and sips (built in).
#
# Usage:
#   ./scripts/convert-to-webp.sh <source-folder> <output-folder>
#   QUALITY=75 MAX_SIDE=1600 ./scripts/convert-to-webp.sh ~/Desktop/fotos ~/Desktop/fotos-webp
#
# Settings (environment variables, optional):
#   QUALITY    WebP quality 0-100                 (default: 80)
#   MAX_SIDE   longest side in px; larger shrinks (default: 1200)
set -euo pipefail

if [ $# -ne 2 ]; then
  echo "Usage: $0 <source-folder> <output-folder>" >&2
  exit 1
fi

SRC_DIR=$1
OUT_DIR=$2
QUALITY=${QUALITY:-80}
MAX_SIDE=${MAX_SIDE:-1200}

command -v cwebp >/dev/null || { echo "cwebp not found. Install it with: brew install webp" >&2; exit 1; }
[ -d "$SRC_DIR" ] || { echo "Source folder not found: $SRC_DIR" >&2; exit 1; }
mkdir -p "$OUT_DIR"

converted=0
resized=0
skipped=0
failed=0
seen=$'\n' # lowercase output names produced in this run, to catch "a.jpg" + "a.png" → "a.webp"

while IFS= read -r f; do
  name=$(basename "$f")
  out_name="${name%.*}.webp"
  key=$(printf '%s' "$out_name" | tr '[:upper:]' '[:lower:]') # macOS folders are case-insensitive

  if [[ "$seen" == *$'\n'"$key"$'\n'* ]]; then
    echo "skipped: $name (another file in this folder already produced $out_name)" >&2
    skipped=$((skipped + 1))
    continue
  fi
  seen+="$key"$'\n'

  read -r w h orientation < <(sips -g pixelWidth -g pixelHeight -g orientation "$f" 2>/dev/null |
    awk '/pixelWidth/{w=$2} /pixelHeight/{h=$2} /orientation/{o=$2} END{print w+0, h+0, (o==""?"<nil>":o)}')

  if [ "$w" -eq 0 ] || [ "$h" -eq 0 ]; then
    echo "failed: $name (could not read the image size)" >&2
    failed=$((failed + 1))
    continue
  fi
  if [ "$orientation" != "<nil>" ] && [ "$orientation" != "1" ]; then
    echo "warning: $name has EXIF orientation $orientation; cwebp ignores it, so the WebP may appear rotated." >&2
  fi

  # cwebp -resize W H: 0 for one side keeps the aspect ratio.
  resize=()
  shrink=0
  if [ "$w" -ge "$h" ] && [ "$w" -gt "$MAX_SIDE" ]; then
    resize=(-resize "$MAX_SIDE" 0); shrink=1
  elif [ "$h" -gt "$w" ] && [ "$h" -gt "$MAX_SIDE" ]; then
    resize=(-resize 0 "$MAX_SIDE"); shrink=1
  fi

  if cwebp -quiet -q "$QUALITY" -m 6 -metadata none ${resize[@]+"${resize[@]}"} "$f" -o "$OUT_DIR/$out_name"; then
    converted=$((converted + 1))
    resized=$((resized + shrink))
  else
    echo "failed: $name (cwebp error)" >&2
    failed=$((failed + 1))
  fi
done < <(find "$SRC_DIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) | sort)

echo "Done: $converted converted ($resized shrunk to ${MAX_SIDE}px), $skipped skipped, $failed failed → $OUT_DIR"
[ "$failed" -eq 0 ]
