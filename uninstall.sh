#!/bin/bash
# Soul Plugin - Uninstaller
#
# Removes the plugin from ~/.claude/plugins/soul and disables it in settings.json.
# Does NOT delete your soul file or daily logs — those are yours to keep.

set -euo pipefail

PLUGIN_DIR="$HOME/.claude/plugins/soul"
SETTINGS="$HOME/.claude/settings.json"

echo "=== Soul Plugin Uninstaller ==="
echo ""

# ---------- remove plugin directory ----------
if [ -d "$PLUGIN_DIR" ]; then
  echo "Removing plugin from $PLUGIN_DIR ..."
  rm -rf "$PLUGIN_DIR"
  echo "  Done."
else
  echo "Plugin directory not found — already removed."
fi

# ---------- disable in settings.json ----------
if [ -f "$SETTINGS" ] && command -v jq &>/dev/null; then
  if jq -e '.enabledPlugins["soul@local"]' "$SETTINGS" &>/dev/null; then
    echo "Removing plugin from settings.json ..."
    TEMP=$(mktemp)
    jq 'del(.enabledPlugins["soul@local"])' "$SETTINGS" > "$TEMP" && mv "$TEMP" "$SETTINGS"
    echo "  Done."
  fi
fi

echo ""
echo "=== Uninstall Complete ==="
echo ""
echo "Your data was preserved:"
echo "  Soul file:  ~/.claude/SOUL.md"
echo "  Daily logs: ~/.claude/memory/"
echo ""
echo "Delete these manually if you no longer want them."
