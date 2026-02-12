#!/bin/bash
# Soul Plugin - Pre-Compaction Memory Flush
#
# Fires before context compaction. Extracts recent context from the conversation
# transcript and appends it to today's daily log, so the post-compaction session
# can pick up where you left off.

set -euo pipefail

# ---------- config ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=config.sh
source "$SCRIPT_DIR/config.sh"

# ---------- dependency check ----------
for cmd in jq python3; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "{\"error\": \"$cmd is required but not installed.\"}" >&2
    exit 1
  fi
done

# ---------- parse hook input ----------
INPUT=$(cat)
TRIGGER=$(echo "$INPUT" | jq -r '.trigger // "unknown"')
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // ""')

# ---------- paths ----------
TODAY=$(date +%Y-%m-%d)
DAILY_LOG="$MEMORY_DIR/$TODAY.md"

mkdir -p "$MEMORY_DIR"

# ---------- extract transcript context (with validation) ----------
RECENT_CONTEXT=""
if [ -n "$TRANSCRIPT_PATH" ] && [ -e "$TRANSCRIPT_PATH" ]; then
  # Resolve symlinks before validation to prevent path-prefix bypasses.
  RESOLVED_TRANSCRIPT_PATH=$(python3 -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "$TRANSCRIPT_PATH" 2>/dev/null || echo "")
  case "$RESOLVED_TRANSCRIPT_PATH" in
    "$HOME"/*|/tmp/*|/private/tmp/*)
      if [ -f "$RESOLVED_TRANSCRIPT_PATH" ]; then
        RECENT_CONTEXT=$(tail -"$TRANSCRIPT_LINES" "$RESOLVED_TRANSCRIPT_PATH" 2>/dev/null | \
          jq -r 'select(.type == "assistant") | .message.content[] | select(.type == "text") | .text' 2>/dev/null | \
          tail -c "$TRANSCRIPT_MAX_CHARS" || echo "")
      fi
      ;;
    *)
      RECENT_CONTEXT="[transcript path outside allowed directories — skipped]"
      ;;
  esac
fi

# ---------- build flush entry ----------
FLUSH_ENTRY="
## Auto-Flush (Pre-Compaction: $TRIGGER)
**Time:** $(date '+%Y-%m-%d %H:%M:%S')
**Trigger:** $TRIGGER compaction

### Recent Context
\`\`\`
${RECENT_CONTEXT:-No transcript context available}
\`\`\`
"

# ---------- append to daily log ----------
if [ -f "$DAILY_LOG" ]; then
  echo "$FLUSH_ENTRY" >> "$DAILY_LOG"
else
  cat > "$DAILY_LOG" << EOF
# Session Log - $TODAY

$FLUSH_ENTRY
EOF
fi

# Restrict permissions — daily logs contain conversation content
chmod 600 "$DAILY_LOG"

# ---------- output for Claude Code ----------
jq -n \
  --arg plugin_name "$PLUGIN_NAME" \
  --arg daily_log "$DAILY_LOG" \
  '{
    hookSpecificOutput: {
      hookEventName: "PreCompact",
      additionalContext: ($plugin_name + " MEMORY FLUSH: Context was auto-saved to " + $daily_log + " before compaction. After compaction, read your soul file and today'\''s session log to restore identity and context.")
    }
  }'

exit 0
