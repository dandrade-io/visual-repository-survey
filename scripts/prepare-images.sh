#!/usr/bin/env bash
# Resizes originals in ./images to web-friendly JPEGs in ./public/images
# and writes public/images.json mapping safe ids -> original filenames.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT=public/images
rm -rf "$OUT"; mkdir -p "$OUT"
i=0
echo "[" > public/images.json
first=1
find images -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) | sort | while IFS= read -r f; do
  i=$((i+1))
  id=$(printf "img-%03d" "$i")
  sips -s format jpeg -s formatOptions 80 -Z 1200 "$f" --out "$OUT/$id.jpg" >/dev/null
  name=$(basename "$f")
  [ $first -eq 1 ] && first=0 || echo "," >> public/images.json
  printf '  {"id":"%s","file":"%s.jpg","original":%s}' "$id" "$id" "$(printf '%s' "$name" | python3 -c 'import json,sys;print(json.dumps(sys.stdin.read()))')" >> public/images.json
done
echo "" >> public/images.json
echo "]" >> public/images.json
echo "Done: $(ls $OUT | wc -l) images, $(du -sh $OUT | cut -f1)"
