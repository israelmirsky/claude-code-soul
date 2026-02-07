#!/bin/bash
# Soul Plugin - Session Bootstrap
#
# Fires on every SessionStart. Reads the soul file and most recent daily log,
# then injects identity context so every session starts with continuity.

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
SOURCE=$(echo "$INPUT" | jq -r '.source // "new"')

# ---------- paths ----------
TODAY=$(date +%Y-%m-%d)
DAILY_LOG="$MEMORY_DIR/$TODAY.md"

# Find the most recent daily log (today's or the last one)
LATEST_LOG=""
if [ -f "$DAILY_LOG" ]; then
  LATEST_LOG="$DAILY_LOG"
elif [ -d "$MEMORY_DIR" ]; then
  LATEST_LOG=$(find "$MEMORY_DIR" -maxdepth 1 -name '*.md' -type f -print0 2>/dev/null | \
    xargs -0 ls -t 2>/dev/null | head -1 || echo "")
fi

# ---------- build bootstrap context ----------
CONTEXT=""

# Add soul summary
if [ -f "$SOUL_FILE" ]; then
  SOUL_SUMMARY=$(head -"$SOUL_LINES" "$SOUL_FILE" 2>/dev/null || echo "")
  CONTEXT="SOUL (from $(basename "$SOUL_FILE")):
$SOUL_SUMMARY
[Full document: $SOUL_FILE]"
fi

# Add recent daily log context
if [ -n "$LATEST_LOG" ] && [ -f "$LATEST_LOG" ]; then
  LOG_TAIL=$(tail -"$LOG_LINES" "$LATEST_LOG" 2>/dev/null || echo "")
  LOG_NAME=$(basename "$LATEST_LOG")
  CONTEXT="$CONTEXT

RECENT LOG ($LOG_NAME):
$LOG_TAIL"
fi

# Add compaction-specific note
if [ "$SOURCE" = "compact" ]; then
  CONTEXT="$CONTEXT

NOTE: This session started after context compaction. Memory was flushed before compaction. Read the full daily log and soul file for complete context."
fi

# Bail if there's nothing to inject
if [ -z "$CONTEXT" ]; then
  echo '{"additionalContext": ""}'
  exit 0
fi

# ---------- escape for JSON ----------
ESCAPED_CONTEXT=$(echo "$CONTEXT" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))' 2>/dev/null \
  || echo '"Soul bootstrap: could not serialize context. Read your soul file manually."')

echo "{\"additionalContext\": $ESCAPED_CONTEXT}"

exit 0
