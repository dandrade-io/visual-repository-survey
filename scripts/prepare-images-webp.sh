#!/usr/bin/env bash
# Converts the originals in ./images to WebP for the web.
#
# - Only shrinks: images whose longest side is above MAX_SIDE are scaled down to it,
#   smaller images keep their original size (never upscaled).
# - Writes <OUT_DIR>/img-XXX.webp and <OUT_DIR>/../images.json (id -> original filename).
# - Ids are assigned in the same sorted order as prepare-images.sh, so img-042 refers to
#   the same original in both versions and existing survey responses stay valid.
#
# Requirements (macOS): cwebp (brew install webp) and sips (built in).
#
# Settings (environment variables, all optional):
#   SRC_DIR    folder with the originals            (default: images)
#   OUT_DIR    folder for the .webp files           (default: public/images) — it is emptied first!
#   MANIFEST   JSON index to write                  (default: <parent of OUT_DIR>/images.json)
#   ID_PREFIX  prefix for the generated names       (default: img → img-001.webp)
#   QUALITY    WebP quality 0-100                   (default: 80)
#   MAX_SIDE   longest side in px, larger shrinks   (default: 1200)
# Relative paths are relative to the project folder; absolute paths work too.
#
# Usage:
#   ./scripts/prepare-images-webp.sh                      # writes public/images + public/images.json
#   OUT_DIR=/tmp/webp-test ./scripts/prepare-images-webp.sh
#   QUALITY=75 MAX_SIDE=1600 ./scripts/prepare-images-webp.sh
#   SRC_DIR=~/Desktop/otras OUT_DIR=~/Desktop/otras-webp/images ID_PREFIX=set2 ./scripts/prepare-images-webp.sh
set -euo pipefail
cd "$(dirname "$0")/.."

SRC_DIR=${SRC_DIR:-images}
OUT_DIR=${OUT_DIR:-public/images}
MANIFEST=${MANIFEST:-$(dirname "$OUT_DIR")/images.json}
ID_PREFIX=${ID_PREFIX:-img}
QUALITY=${QUALITY:-80}
MAX_SIDE=${MAX_SIDE:-1200}

command -v cwebp >/dev/null || { echo "cwebp not found. Install it with: brew install webp" >&2; exit 1; }
[ -d "$SRC_DIR" ] || { echo "Missing $SRC_DIR/ with the original images." >&2; exit 1; }

# OUT_DIR is emptied before converting, so compare fully resolved paths and refuse
# anything that would delete the originals, the project, the home folder or more.
SRC_ABS=$(cd "$SRC_DIR" && pwd -P)
OUT_ABS=$(mkdir -p "$OUT_DIR" && cd "$OUT_DIR" && pwd -P)
PROJECT_ABS=$(pwd -P)
HOME_ABS=$(cd "$HOME" && pwd -P)
case "$OUT_ABS" in
  / | "$HOME_ABS" | "$PROJECT_ABS" | "$SRC_ABS")
    echo "Refusing OUT_DIR=$OUT_DIR: it resolves to $OUT_ABS, which would be emptied." >&2; exit 1 ;;
esac
case "$SRC_ABS/" in
  "$OUT_ABS"/*) echo "Refusing OUT_DIR=$OUT_DIR: it contains SRC_DIR, which would be deleted." >&2; exit 1 ;;
esac

rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

json_escape() { python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$1"; }

i=0
resized=0
kept=0
entries=()

while IFS= read -r f; do
  i=$((i + 1))
  id=$(printf "%s-%03d" "$ID_PREFIX" "$i")
  name=$(basename "$f")

  read -r w h orientation < <(sips -g pixelWidth -g pixelHeight -g orientation "$f" 2>/dev/null |
    awk '/pixelWidth/{w=$2} /pixelHeight/{h=$2} /orientation/{o=$2} END{print w, h, (o==""?"<nil>":o)}')

  if [ "$orientation" != "<nil>" ] && [ "$orientation" != "1" ]; then
    echo "warning: $name has EXIF orientation $orientation; cwebp ignores it, so the WebP may appear rotated." >&2
  fi

  # cwebp -resize W H: 0 for one side keeps the aspect ratio.
  resize=()
  if [ "$w" -ge "$h" ] && [ "$w" -gt "$MAX_SIDE" ]; then
    resize=(-resize "$MAX_SIDE" 0); resized=$((resized + 1))
  elif [ "$h" -gt "$w" ] && [ "$h" -gt "$MAX_SIDE" ]; then
    resize=(-resize 0 "$MAX_SIDE"); resized=$((resized + 1))
  else
    kept=$((kept + 1))
  fi

  cwebp -quiet -q "$QUALITY" -m 6 -metadata none ${resize[@]+"${resize[@]}"} "$f" -o "$OUT_DIR/$id.webp"

  entries+=("  {\"id\":\"$id\",\"file\":\"$id.webp\",\"original\":$(json_escape "$name")}")
done < <(find "$SRC_DIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) | sort)

{
  echo "["
  for ((k = 0; k < ${#entries[@]}; k++)); do
    if [ "$k" -lt $((${#entries[@]} - 1)) ]; then echo "${entries[$k]},"; else echo "${entries[$k]}"; fi
  done
  echo "]"
} > "$MANIFEST"

echo "Done: $i images → $OUT_DIR ($(du -sh "$OUT_DIR" | cut -f1)); $resized shrunk to ${MAX_SIDE}px, $kept kept at original size."
echo "Manifest: $MANIFEST"
