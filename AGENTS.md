# Agent Startup

This repository uses an agent-agnostic startup routine.

Before making changes, read and follow:

```text
docs/00-context/agent-startup.md
```

Then run the read-only startup helper:

```sh
./scripts/session-start.sh
```

All durable project memory belongs under `docs/`. Do not store important context only in one agent's private memory.

