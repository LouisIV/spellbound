#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
iconset=.build/Spellbound.iconset
mkdir -p "$iconset" Apps/SpellboundMac/Resources
for size in 16 32 128 256 512; do
  sips -z "$size" "$size" assets/icons/spellbound-key.png \
    --out "$iconset/icon_${size}x${size}.png" >/dev/null
  pixels=$((size * 2))
  sips -z "$pixels" "$pixels" assets/icons/spellbound-key.png \
    --out "$iconset/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$iconset" -o Apps/SpellboundMac/Resources/Spellbound.icns
