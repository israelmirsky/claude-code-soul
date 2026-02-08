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
if ! command -v jq &>/dev/null; then
  echo '{"error": "jq is required but not installed. Install: brew install jq"}' >&2
  exit 1
fi

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
if [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]; then
  # Security: only read files under $HOME or /tmp (where Claude Code writes transcripts)
  case "$TRANSCRIPT_PATH" in
    "$HOME"/*|/tmp/*|/private/tmp/*)
      RECENT_CONTEXT=$(tail -"$TRANSCRIPT_LINES" "$TRANSCRIPT_PATH" 2>/dev/null | \
        jq -r 'select(.type == "assistant") | .message.content[] | select(.type == "text") | .text' 2>/dev/null | \
        tail -c "$TRANSCRIPT_MAX_CHARS" || echo "")
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
cat << JSONEOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreCompact",
    "additionalContext": "$PLUGIN_NAME MEMORY FLUSH: Context was auto-saved to $DAILY_LOG before compaction. After compaction, read your soul file and today's session log to restore identity and context."
  }
}
JSONEOF

exit 0
