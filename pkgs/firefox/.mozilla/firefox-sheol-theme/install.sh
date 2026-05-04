#!/usr/bin/env bash
# Helper: copy userChrome.css into your active Firefox profile

set -e

PROFILE_DIR=$(find "$HOME/.mozilla/firefox" -maxdepth 1 -type d -name "*.default-release" | head -1)
if [ -z "$PROFILE_DIR" ]; then
    PROFILE_DIR=$(find "$HOME/.mozilla/firefox" -maxdepth 1 -type d -name "*.default*" | head -1)
fi

if [ -z "$PROFILE_DIR" ]; then
    echo "✘ no Firefox profile found in ~/.mozilla/firefox"
    echo "  start Firefox once to create the default profile, then re-run"
    exit 1
fi

mkdir -p "$PROFILE_DIR/chrome"
cp "$(dirname "$0")/userChrome.css" "$PROFILE_DIR/chrome/userChrome.css"
echo "✓ installed userChrome.css to $PROFILE_DIR/chrome/"
echo ""
echo "next:"
echo "  1. open Firefox"
echo "  2. type 'about:config' in address bar"
echo "  3. search for 'toolkit.legacyUserProfileCustomizations.stylesheets'"
echo "  4. set it to true"
echo "  5. restart Firefox"
