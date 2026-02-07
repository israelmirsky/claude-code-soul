#!/bin/bash
# Soul Plugin - Installer
#
# Copies the plugin to ~/.claude/plugins/soul and enables it in settings.json.
# Safe to re-run — won't overwrite existing soul files or daily logs.

set -euo pipefail

PLUGIN_DIR="$HOME/.claude/plugins/soul"
SETTINGS="$HOME/.claude/settings.json"
SOUL_FILE="$HOME/.claude/SOUL.md"
MEMORY_DIR="$HOME/.claude/memory"
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Soul Plugin Installer ==="
echo ""

# ---------- dependency check ----------
MISSING=""
for cmd in jq python3; do
  if ! command -v "$cmd" &>/dev/null; then
    MISSING="$MISSING $cmd"
  fi
done

if [ -n "$MISSING" ]; then
  echo "ERROR: Missing required dependencies:$MISSING"
  echo "Install with: brew install${MISSING}"
  exit 1
fi

# ---------- install plugin ----------
echo "Installing plugin to $PLUGIN_DIR ..."
mkdir -p "$PLUGIN_DIR/.claude-plugin"
mkdir -p "$PLUGIN_DIR/hooks"
mkdir -p "$PLUGIN_DIR/scripts"

cp "$SOURCE_DIR/.claude-plugin/plugin.json" "$PLUGIN_DIR/.claude-plugin/plugin.json"
cp "$SOURCE_DIR/hooks/hooks.json"            "$PLUGIN_DIR/hooks/hooks.json"
cp "$SOURCE_DIR/scripts/config.sh"           "$PLUGIN_DIR/scripts/config.sh"
cp "$SOURCE_DIR/scripts/memory-flush.sh"     "$PLUGIN_DIR/scripts/memory-flush.sh"
cp "$SOURCE_DIR/scripts/session-bootstrap.sh" "$PLUGIN_DIR/scripts/session-bootstrap.sh"

chmod +x "$PLUGIN_DIR/scripts/memory-flush.sh"
chmod +x "$PLUGIN_DIR/scripts/session-bootstrap.sh"

echo "  Done."

# ---------- create memory directory ----------
if [ ! -d "$MEMORY_DIR" ]; then
  echo "Creating memory directory at $MEMORY_DIR ..."
  mkdir -p "$MEMORY_DIR"
  chmod 700 "$MEMORY_DIR"
  echo "  Done."
fi

# ---------- create soul file if missing ----------
if [ ! -f "$SOUL_FILE" ]; then
  echo "Creating starter soul file at $SOUL_FILE ..."
  cp "$SOURCE_DIR/examples/SOUL.md" "$SOUL_FILE"
  chmod 600 "$SOUL_FILE"
  echo "  Done. Edit this file to define your working identity."
else
  echo "Soul file already exists at $SOUL_FILE — not overwriting."
fi

# ---------- enable in settings.json ----------
if [ -f "$SETTINGS" ]; then
  if jq -e '.enabledPlugins["soul@local"]' "$SETTINGS" &>/dev/null; then
    echo "Plugin already enabled in settings.json."
  else
    echo "Enabling plugin in settings.json ..."
    TEMP=$(mktemp)
    jq '.enabledPlugins["soul@local"] = true' "$SETTINGS" > "$TEMP" && mv "$TEMP" "$SETTINGS"
    echo "  Done."
  fi
else
  echo "Creating settings.json with plugin enabled ..."
  mkdir -p "$(dirname "$SETTINGS")"
  cat > "$SETTINGS" << 'EOF'
{
  "enabledPlugins": {
    "soul@local": true
  }
}
EOF
  echo "  Done."
fi

echo ""
echo "=== Installation Complete ==="
echo ""
echo "Next steps:"
echo "  1. Edit ~/.claude/SOUL.md to define your working identity"
echo "  2. Restart Claude Code (or start a new session)"
echo "  3. Your identity and memory will now persist across sessions"
echo ""
echo "Configuration: $PLUGIN_DIR/scripts/config.sh"
echo "Daily logs:    $MEMORY_DIR/"
echo "Soul file:     $SOUL_FILE"
