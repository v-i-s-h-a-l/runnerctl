# AI Coding Agent Conventions — Research Findings

Source: parallel research workflow (`w8m6fmm1x`) covering 6 AI coding agents, June 2026. Raw structured output is preserved in the session task store; this document is the human-readable synthesis.

## Headline Findings

1. **`AGENTS.md` is the only universal file.** Five of six agents (Claude Code, Cursor, Codex CLI, GitHub Copilot, Cline) read it natively. Aider needs a one-line `read: AGENTS.md` opt-in in `.aider.conf.yml`. This is the single highest-leverage file in the agent layer.

2. **No agent has a hard-coded natural-language → tool router.** All six rely on the LLM reasoning over loaded instruction files. A literal "When user asks X, run `runnerctl Y`" table in AGENTS.md is the load-bearing artifact.

3. **MCP is the typed-tool channel for five of six agents.** A single `runnerctl mcp` subcommand exposing the verbs as typed tools serves Claude Code, Codex, Cursor, Copilot, and Cline simultaneously. Aider (vanilla CLI) has no MCP; AiderDesk does. This is the highest-leverage CLI code investment.

4. **`SKILL.md` format converges across three first-tier agents.** Claude Code (`.claude/skills/`), Codex (`.agents/skills/`), and Cursor (`.cursor/skills/`) all use the same YAML-frontmatter + Markdown body shape. One authored source can serve all three vendor paths.

5. **Session-start orchestration is uneven.** Claude Code, Codex, Cursor, and Copilot CLI all support simple JSON hook declarations. Cline requires a TypeScript SDK plugin (heavier). Aider uses `.aider.conf.yml` + `/load` script. VS Code Copilot agent mode has no session-start hook at all.

6. **Session-detection env vars are inconsistent.** Reliable markers exist for Claude Code (`CLAUDECODE=1`), Cline (`CLINE_ACTIVE=true`), and Cursor (`CURSOR_PROJECT_DIR`). Codex, Copilot, and Aider have no stable session markers documented. Runnerhub must set its own `RUNNERHUB_AGENT=<vendor>` from each hook to insulate against vendor drift.

## Recommended Architecture

A three-phase rollout, with most leverage in Phase 1.

### Phase 1 — Universal Layer (ships first, zero new CLI code)

Files at repo root:

```text
/AGENTS.md                                  # ~150 lines, six fixed sections
/CLAUDE.md                                  # 10-line adapter → docs/00-context/agent-startup.md (already exists)
/GEMINI.md                                  # 10-line adapter (already exists)
/.github/copilot-instructions.md            # 10-line adapter (new — Copilot's stable surface)
/docs/00-context/agent-startup.md           # canonical context (already exists)
/docs/00-context/agent-command-menu.md      # NEW: single source for the command table
/scripts/session-start.sh                   # already exists; harden to detect agent env vars + emit JSON
```

**`AGENTS.md` structure (six sections):**

1. Project identity (one paragraph)
2. Hard safety rules (single trusted machine, macOS first / Linux second, secrets policy, sudo policy)
3. Canonical command menu (literal table of every top-level verb)
4. NL→command routing block (load-bearing — most agents have no declarative router)
5. Agent-output contract (`--agent` flag and env-var auto-detection switch to JSON, no spinners, no prompts)
6. Pointer to `docs/00-context/agent-startup.md`

### Phase 2 — First-Class Agents (Claude Code + Codex)

```text
/skills/<verb>/SKILL.md                     # NEW canonical source for five verbs (add, doctor, status, repair, remove)
/.claude/settings.json                      # SessionStart hook → scripts/session-start.sh --agent claude
/.claude/skills/<verb>/SKILL.md             # symlink or copy of /skills/<verb>/SKILL.md
/.codex/hooks.json                          # SessionStart hook → scripts/session-start.sh --agent codex
/.agents/skills/<verb>/SKILL.md             # symlink or copy of /skills/<verb>/SKILL.md
```

### Phase 3 — MCP Server (largest CLI code investment; serves five agents at once)

New `runnerctl mcp` subcommand speaking stdio MCP, exposing typed tools:
`add_runner`, `list_runners`, `doctor`, `repair_runner`, `remove_runner`.

```text
/.mcp.json                                  # Claude Code project MCP declaration
/.codex/config.toml                         # [mcp_servers.runnerctl] entry
/.cursor/mcp.json                           # Cursor project MCP
/.vscode/mcp.json                           # VS Code Copilot workspace MCP
# Cline: submit to github.com/cline/mcp-marketplace for one-click install
```

### Explicitly Deferred

- Cursor-specific `.cursor/rules/*.mdc`, `.cursor/commands/*`, `.cursor/skills/*` — AGENTS.md + MCP cover the same surface.
- Copilot `.github/prompts/*.prompt.md` and `.github/chatmodes/*` — VS Code-only, discoverability-only.
- Cline SDK plugin and `.clinerules/` directory — add a single `.clinerules/runnerctl.md` later if a Cline user requests it.
- Aider `.aider.conf.yml` + `/load` script — add only if a real Aider user surfaces.

### Key Architectural Calls

1. `/skills/<verb>/SKILL.md` as the single canonical authored location prevents drift between Claude Code and Codex skills.
2. `scripts/session-start.sh` as the one orient script every agent's hook invokes; the script is shared, the hook configs differ in *how* they call it.
3. `/docs/00-context/agent-command-menu.md` as the one machine- and human-readable command catalog. AGENTS.md's routing table, the SKILL.md descriptions, and MCP tool schemas should all reference or be generated from it.
4. `RUNNERHUB_AGENT=<vendor>` is the canonical in-CLI session marker. Each hook exports it before the agent loop begins. This insulates runnerctl from per-vendor env-var drift.

## Why Claude Code + Codex As The Two First-Class Agents

**Claude Code (slot 1):** Non-negotiable. The maintainer uses it daily, so every iteration of the onboarding layer is dogfooded for free. Cleanest extension surface: SessionStart hook is one line in `settings.json`, Skills auto-invoke on description match, `CLAUDECODE=1` is a reliable marker, `.mcp.json` is project-scoped and checked-in.

**Codex CLI (slot 2):** Justified despite the maintenance cost because:
- Skills live at `.agents/skills/<name>/SKILL.md` with the same YAML-frontmatter + description-triggered shape as Claude Code Skills. Authoring once and symlinking is ~5% incremental cost.
- Codex is the second-most-likely agent for runnerctl's target user (indie devs in the OpenAI ecosystem).
- Codex's progressive-disclosure Skill loading is the closest thing to a declarative intent router in the entire survey.

**Explicitly not picking:** Cursor and Copilot are covered by the universal layer + MCP server (Phase 3), no per-agent skill authoring needed. Cline has CLINE_ACTIVE detection and a marketplace but its hook model requires a TypeScript plugin (too heavy). Aider has no skill registry and no native MCP — standard depth only via AGENTS.md + .aider.conf.yml.

## Per-Agent Summary

### Claude Code — first-class
- Reads CLAUDE.md (canonical) and AGENTS.md.
- SessionStart hook via `.claude/settings.json`, runs any shell command or MCP tool.
- Skills at `.claude/skills/<name>/SKILL.md` with autonomous (description-triggered) invocation; slash commands at `.claude/commands/<name>.md`.
- MCP first-class via `.mcp.json` at repo root.
- Session marker: `CLAUDECODE=1` reliable.

### Codex CLI (OpenAI) — first-class
- Reads `AGENTS.md` (canonical, also reads `AGENTS.override.md` and configurable fallbacks).
- SessionStart hook via `.codex/hooks.json`.
- Skills at `.agents/skills/<name>/SKILL.md`, same SKILL.md format as Claude Code.
- MCP first-class via `[mcp_servers.<name>]` in `.codex/config.toml`.
- Session marker: none documented; set `RUNNERHUB_AGENT=codex` from the hook.
- Caveat: project-scoped `.codex/config.toml` and `.codex/hooks.json` require the project to be "trusted" (direnv-style prompt).

### Cursor — covered by universal layer + MCP
- Reads `AGENTS.md` (nested supported) and `.cursor/rules/*.mdc`.
- SessionStart hook via `.cursor/hooks.json` (fire-and-forget; can return JSON to inject context).
- Slash commands at `.cursor/commands/`; Skills at `.cursor/skills/`.
- MCP first-class via `.cursor/mcp.json`.
- Session marker: `CURSOR_PROJECT_DIR` reliable; `CURSOR_AGENT=1` intended but known to be inconsistent.

### GitHub Copilot — covered by universal layer + MCP
- Reads `.github/copilot-instructions.md` (primary), `.github/instructions/*.instructions.md` (path-scoped), `AGENTS.md` (coding agent + cloud agent).
- SessionStart hook via `.github/copilot/settings.json` (Copilot CLI only; VS Code agent mode does NOT support session hooks).
- Slash commands via `.github/prompts/*.prompt.md`; chat modes via `.github/chatmodes/*.chatmode.md` (VS Code only).
- MCP first-class via `.vscode/mcp.json` (workspace) or user-profile mcp.json.
- Session marker: none stable as of June 2026; open feature requests `microsoft/vscode#265446` and `github/copilot-cli#2107`.
- Surface fragments across three SKUs (VS Code agent mode, async cloud coding agent, Copilot CLI); `AGENTS.md` is the only thing all three honor.

### Cline — covered by universal layer + MCP (marketplace)
- Reads `.clinerules/` directory (preferred; all `.md` files concatenated) and `AGENTS.md`.
- SessionStart hooks require authoring a TypeScript SDK plugin (heavier than other agents).
- Workflows at `.clinerules/workflows/<name>.md` become `/<name>.md` slash commands.
- MCP first-class with one-click marketplace install at `github.com/cline/mcp-marketplace`.
- Session marker: `CLINE_ACTIVE=true` reliable (shipped v3.24.0).

### Aider — standard depth (files only)
- Does NOT auto-read any markdown file by filename. Requires `read: CONVENTIONS.md` (or `read: AGENTS.md`) in `.aider.conf.yml`.
- "SessionStart" is the `--load <file>` flag / `load:` key in `.aider.conf.yml` that replays slash commands at launch (`/run runnerctl status`, etc.).
- No user-extensible custom slash commands.
- No MCP in vanilla CLI; only AiderDesk has MCP.
- Session marker: none; workaround is to set `env: ['RUNNERHUB_AGENT=aider']` in `.aider.conf.yml`.

## Common Patterns Across All Six

- All read Markdown at repo root as system context on every session.
- All route natural language via LLM reasoning over loaded instructions; none have hard-coded keyword routers.
- All can shell out to scripts — `scripts/session-start.sh` can be the one shared script every agent's hook invokes.
- All reward emitting machine-readable JSON when invoked non-interactively.
- Skill/command file conventions converge on `SKILL.md` with YAML frontmatter and a `description` field used for autonomous invocation (across Claude Code, Codex, Cursor).
- Five of six support MCP as the typed-tool channel.

## Divergent Patterns

- Hook weight ranges from "one line in JSON" (Claude, Codex, Cursor, Copilot CLI) to "author a TypeScript plugin" (Cline) to "`/load` a command script via YAML config" (Aider).
- Skill directory paths differ: `.claude/skills/`, `.agents/skills/`, `.cursor/skills/`, `.github/prompts/` + `.github/chatmodes/`, `.clinerules/workflows/`. SKILL.md *content* is portable; *paths* are not.
- Session-detection env vars: reliable for Claude/Cline/Cursor; absent or unstable for Codex/Copilot/Aider.
- MCP integration is absent in vanilla Aider; first-class in all other five.
- Copilot's surface fragments into three SKUs with different file support.

## Open Questions For The Maintainer To Close

1. **Skill source layout** — single `/skills/<verb>/SKILL.md` with symlinks into `/.claude/skills` and `/.agents/skills`, or maintain copies with a `make sync-skills` target? Symlinks are DRY but break on Windows (Copilot users); copies are bulletproof. *Lean: copies + sync target.*

2. **MCP server timing** — build `runnerctl mcp` in Phase 2 alongside skills, or defer to Phase 3? Earlier MCP means five agents get typed tools immediately and skill bodies stay thin; later MCP ships Phases 1–2 faster but skill bodies must template CLI args. *Lean: defer to Phase 3 unless the CLI surface is churning.*

3. **Adapter vs duplicate for `CLAUDE.md` / `GEMINI.md` / `.github/copilot-instructions.md`** — 10-line pointers to AGENTS.md, or full content duplication? Adapters are DRY; duplicates load on first pass. *Lean: adapters for CLAUDE.md/GEMINI.md, full content for copilot-instructions.md (Copilot's cloud agent is less reliable about indirections).*

4. **Auto-orient script behavior** — should `scripts/session-start.sh` just print status, or also offer an action menu? Verbose first-turn output increases context cost; terse output requires the user to ask. *Lean: terse JSON status when `--agent` is set; let SKILL.md descriptions carry the menu.*

5. **Second deep-integration slot — Codex or Cursor?** Codex wins on SKILL.md reuse. Cursor has stronger MCP UX and larger indie-dev share. The synthesis bet on Codex; should be sanity-checked against target-user telemetry if available.

6. **Telemetry** — does runnerctl want to record `RUNNERHUB_AGENT=<vendor>` for product analytics? Trivial to add but has privacy implications worth a deliberate call.

7. **Distribution of agent-specific config** — ship the `.claude/`, `.codex/`, `.cursor/`, `.vscode/` directories *in the runnerctl repo*, or generate them via `runnerctl init` in the user's target repo? *Lean: ship in-repo for first-class agents (Claude/Codex); generate-on-demand for the rest.*

## What Changes In The Roadmap

The agent-orchestration goal (#10 in `goals-and-non-goals.md`) needs its own milestone phasing inside the existing roadmap. Suggested:

- **M0 (Scope Lock & Research)** — incorporate this findings doc; close at least the seven open questions above.
- **M1 (Foundations + Doctor)** — also includes Phase 1 of the agent layer: `AGENTS.md`, adapters, hardened `session-start.sh`.
- **M2 (Single Runner)** — also includes Phase 2: Claude Code + Codex skills and hooks.
- **M3 (Multi-Target Lifecycle)** — also includes Phase 3: `runnerctl mcp` subcommand and MCP declarations for the five MCP-capable agents.

A roadmap update is appropriate once the open questions are closed.
