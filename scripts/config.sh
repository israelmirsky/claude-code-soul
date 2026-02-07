#!/bin/bash
# Soul Plugin - Configuration
#
# All values have sensible defaults. Override by setting environment variables
# or editing this file directly.

# Path to your soul/identity document
SOUL_FILE="${SOUL_FILE:-$HOME/.claude/SOUL.md}"

# Directory for daily session logs
MEMORY_DIR="${MEMORY_DIR:-$HOME/.claude/memory}"

# Lines of soul file to inject on session start (keeps token usage lean)
SOUL_LINES="${SOUL_LINES:-50}"

# Lines of daily log tail to inject on session start
LOG_LINES="${LOG_LINES:-30}"

# Lines of transcript to capture before compaction
TRANSCRIPT_LINES="${TRANSCRIPT_LINES:-50}"

# Max characters of transcript context to save per flush
TRANSCRIPT_MAX_CHARS="${TRANSCRIPT_MAX_CHARS:-2000}"

# Display name used in log entries
PLUGIN_NAME="${PLUGIN_NAME:-Soul}"
