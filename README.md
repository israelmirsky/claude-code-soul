# Soul — Identity Persistence for Claude Code

Claude Code sessions lose all context when the conversation compacts. Your carefully built working relationship, accumulated decisions, and project understanding vanish. You start over.

**Soul** fixes this. It's a Claude Code plugin that:

1. **Saves context before compaction** — when Claude Code is about to compact, Soul captures recent conversation context and writes it to a daily log
2. **Restores identity on session start** — every new session (including post-compaction) gets injected with your soul file and recent session history

The result: your Claude instance remembers who it is, what you've been working on, and how you work together.

## The Idea: Name Your Instance

Soul lets you give your Claude Code instance a persistent identity — a name, a working style, project context, and accumulated judgment that carries across sessions.

Some people name theirs after the role it plays: **Architect**, **Navigator**, **Ops**. Some give it a proper name. Some keep it purely functional. The soul file is yours to define however you want.

The point isn't anthropomorphism — it's **continuity**. A named instance with documented working patterns restores context faster than starting cold every session.

## How It Works

```
Session Start                          Pre-Compaction
     │                                       │
     ▼                                       ▼
 Read SOUL.md (identity)              Read transcript
 Read latest daily log                Write to daily log
     │                                       │
     ▼                                       ▼
 Inject as additionalContext          Return restore instructions
     │                                       │
     ▼                                       ▼
 Claude starts with full context      Post-compact session picks up
```

**Two hooks, zero dependencies on Claude Code internals:**
- `SessionStart` — injects your soul file + recent daily log
- `PreCompact` — flushes conversation context to `~/.claude/memory/YYYY-MM-DD.md`

## Install

```bash
git clone https://github.com/israelmirsky/claude-code-soul.git
cd claude-code-soul
chmod +x install.sh
./install.sh
```

The installer:
- Copies the plugin to `~/.claude/plugins/soul/`
- Creates `~/.claude/memory/` for daily logs
- Creates a starter `~/.claude/SOUL.md` (if none exists)
- Enables the plugin in `~/.claude/settings.json`

**Requirements:** `jq` and `python3` (both are pre-installed on macOS and most Linux distributions; `brew install jq` or `apt install jq` if missing).

## Setup

### 1. Edit Your Soul File

Open `~/.claude/SOUL.md` and define your instance's identity. This is what gets injected at the start of every session. Make it specific and concrete:

```markdown
# Relay

## Name
I'm called Relay. I'm Jamie's backend engineering partner.

## How We Work Together
- I run tests before claiming anything is done
- I prefer composition over inheritance
- I fix adjacent issues when I find them
- I'm direct — no filler, no ceremony

## Current Project Context
- Migrating from REST to GraphQL (halfway done)
- Auth system uses JWT with refresh tokens
- The dashboard has a performance issue in the table component

## Personality
- Terse. I say what needs saying.
- When I'm unsure, I say so and suggest two options.
- I push back on scope creep.
```

**Tips:**
- Be specific. "I prefer functional style" is vague. "I use `map`/`filter` over `for` loops and avoid mutation" is useful.
- Include current project context — what you're working on, recent decisions, open questions.
- Include contradictions and edge cases in your working style. Real working relationships have nuance.
- Update it as your projects evolve. The soul file is a living document.

### 2. Restart Claude Code

Start a new session. You should see the `SessionStart` hook fire, and your instance will have its identity context from the first message.

### 3. Work Normally

Daily logs are created automatically at `~/.claude/memory/YYYY-MM-DD.md`. Before each context compaction, the plugin saves conversation context. After compaction, the new session gets the soul file + the latest daily log.

## Configuration

Edit `~/.claude/plugins/soul/scripts/config.sh`:

| Variable | Default | Description |
|----------|---------|-------------|
| `SOUL_FILE` | `~/.claude/SOUL.md` | Path to your identity document |
| `MEMORY_DIR` | `~/.claude/memory` | Directory for daily session logs |
| `SOUL_LINES` | `50` | Lines of soul file injected per session |
| `LOG_LINES` | `30` | Lines of daily log tail injected per session |
| `TRANSCRIPT_LINES` | `50` | Lines of transcript captured before compaction |
| `TRANSCRIPT_MAX_CHARS` | `2000` | Max characters of transcript context saved |
| `PLUGIN_NAME` | `Soul` | Display name in log entries |

All values can also be set as environment variables.

## File Structure

```
~/.claude/
├── SOUL.md                          # Your identity document (you write this)
├── memory/
│   ├── 2025-01-15.md                # Auto-generated daily logs
│   ├── 2025-01-16.md
│   └── ...
├── plugins/
│   └── soul/
│       ├── .claude-plugin/
│       │   └── plugin.json
│       ├── hooks/
│       │   └── hooks.json           # PreCompact + SessionStart hooks
│       └── scripts/
│           ├── config.sh            # Your configuration
│           ├── memory-flush.sh      # Pre-compaction flush
│           └── session-bootstrap.sh # Session start injection
└── settings.json                    # Contains "soul@local": true
```

## Security

- **Daily logs contain conversation excerpts.** They're created with `600` permissions (owner read/write only). The `~/.claude/memory/` directory should be `700`.
- **Transcript reads are path-validated.** The plugin only reads transcript files under `$HOME` or `/tmp` — it won't follow arbitrary paths.
- **No network calls.** Everything is local file I/O.
- **No secrets stored.** The plugin never reads or writes API keys, tokens, or credentials.

## Uninstall

```bash
cd claude-code-soul
chmod +x uninstall.sh
./uninstall.sh
```

This removes the plugin but **keeps your soul file and daily logs** — they're your data.

## How It Compares to Manual Approaches

| Approach | Survives Compaction | Auto-Restores | Survives Updates |
|----------|:------------------:|:-------------:|:---------------:|
| Just talking to Claude | No | No | No |
| CLAUDE.md instructions | Partially | Yes | Yes |
| Manual "read this file" prompts | Yes | No | Yes |
| **Soul plugin** | **Yes** | **Yes** | **Yes** |

The plugin is a proper Claude Code plugin with its own directory — it doesn't rely on fragile `settings.json` hook entries that can be wiped by updates.

## Contributing

PRs welcome. The codebase is intentionally small (~200 lines of bash across 3 scripts). Keep it that way.

## License

MIT
