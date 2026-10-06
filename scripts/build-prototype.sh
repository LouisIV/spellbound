#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .build dist
if [[ "$(tuist version)" != "4.184.1" ]]; then
  echo 'Use Tuist 4.184.1 (mise install).' >&2
  exit 1
fi
tuist generate --no-open --cache-profile none
tuist xcodebuild build -workspace Spellbound.xcworkspace -scheme SpellboundMac \
  -configuration Debug -destination 'platform=macOS' \
  -derivedDataPath .build/DerivedData CODE_SIGNING_ALLOWED=NO
if pgrep -x SpellboundMac >/dev/null; then
  echo 'Quit Spellbound before replacing the prototype, then run this script again.' >&2
  exit 1
fi
ditto .build/DerivedData/Build/Products/Debug/SpellboundMac.app dist/Spellbound.app
# Set SPELLBOUND_SIGN_IDENTITY to a local development identity to preserve its identity across rebuilds.
codesign --force --deep --sign "${SPELLBOUND_SIGN_IDENTITY:--}" --identifier dev.spellbound.mac dist/Spellbound.app
codesign --verify --deep --strict dist/Spellbound.app
printf 'Ready: %s/dist/Spellbound.app\n' "$PWD"
