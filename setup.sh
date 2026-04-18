#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

echo "→ Napat Dev setup"

if ! command -v xcodegen >/dev/null 2>&1; then
    echo "xcodegen not found."
    if command -v brew >/dev/null 2>&1; then
        echo "→ Installing xcodegen via Homebrew…"
        brew install xcodegen
    else
        cat <<'EOF'

xcodegen is required to generate the Xcode project. Install it one of these ways:

  • Homebrew:  brew install xcodegen
  • Mint:      mint install yonaskolb/XcodeGen

Then re-run: ./setup.sh
EOF
        exit 1
    fi
fi

echo "→ Generating NapatDev.xcodeproj"
xcodegen generate

cat <<'EOF'

Done. Next steps:

  1. Open NapatDev.xcodeproj in Xcode.
  2. Select each target (NapatDev-iOS, NapatDev-macOS) → Signing & Capabilities
     → pick your (free) personal Apple ID team.
  3. Build & run:
       • ⌘R with scheme "NapatDev-macOS" to launch the desktop app.
       • ⌘R with scheme "NapatDev-iOS" to launch in the Simulator.
  4. (Optional) Drop OFL font TTFs into NapatDev/Resources/Fonts/ — see
     FONTS_README.md in that folder.

EOF
