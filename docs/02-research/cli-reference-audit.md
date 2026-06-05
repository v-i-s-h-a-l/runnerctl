# CLI Reference Audit

## Purpose

This audit captures patterns from adjacent CLIs that Runnerctl should copy or intentionally avoid. The goal is not novelty. The goal is a small lifecycle CLI whose behavior is obvious to people who already use tools like `gh`, `brew`, `docker`, and service managers.

## Sources

- GitHub CLI manual: <https://cli.github.com/manual/>
- GitHub CLI auth reference: <https://cli.github.com/manual/gh_auth>
- Docker CLI formatting reference: <https://docs.docker.com/engine/cli/formatting/>
- Docker inspect reference: <https://docs.docker.com/reference/cli/docker/inspect/>
- GitHub self-hosted runner REST API: <https://docs.github.com/en/rest/actions/self-hosted-runners>
- GitHub self-hosted runner workflow labels: <https://docs.github.com/en/actions/how-tos/manage-runners/self-hosted-runners/use-in-a-workflow>

## Pattern Matrix

| Area | Observed pattern | Runnerctl decision pressure |
| --- | --- | --- |
| First command | `gh` starts with `gh auth login`; service CLIs usually have a setup/login verb before lifecycle verbs. | Use `runnerctl login` as the explicit first command. Let `runnerctl add` detect missing auth and offer to run login interactively. |
| Auth | `gh auth login` supports browser/device-style auth, token input, host selection, and account switching. | Reuse `gh` when possible, but do not assume it is clean. Runnerctl needs `login`, `login --account`, `login --with-token`, and `login --refresh`. |
| Lifecycle verbs | `docker`, `brew services`, and process managers expose simple verbs: list/status/start/stop/remove/update. | Keep top-level verbs boring: `add`, `list`, `status`, `doctor`, `repair`, `remove`, `update`, `login`, `logout`, `agents`. |
| Doctor behavior | `brew doctor` is a separate diagnostic command, not a hidden side effect of every command. | `doctor` should be explicit and heavier than `status`. `status` is daily; `doctor` is investigative. |
| Output | `gh` commonly uses human output by default and `--json` for scripts; Docker has JSON/native formatting for inspect-like commands. | Human output by default. Every command supports `--json`. Do not require template support in v1. |
| Destructive confirmation | CLIs commonly prompt for destructive changes and provide `--yes` or `--force` for automation. | `remove` and reset-style repair require confirmation unless `--yes`. Non-destructive idempotent commands should not prompt unless they need a strategy choice. |
| Target ambiguity | Docker has explicit `--type` when names collide across resource types. | `runnerctl add acme` can mean org/user-owned target only if GitHub lookup is unambiguous. Use `--scope repo|org` to resolve ambiguity. |
| Progress output | Install/setup CLIs stream steps and finish with a concise next action. | `add`, `repair`, `remove`, and `update` should print a plan, stream steps, and end with one concrete next action. |
| Machine-readable mode | `gh` field-specific `--json` is powerful but adds surface area; Docker JSON is broad. | Start with `--json` returning a stable typed envelope for each command. Add `--jq`/templates only if users ask. |
| Environment variables | `gh` honors token env vars for automation. | Support `GITHUB_TOKEN`, `GH_TOKEN`, and `GH_HOST` where safe, but prefer stored auth for interactive local use. |

## Command Shape Recommendation

The CLI should feel like a small resource controller:

```text
runnerctl login
runnerctl doctor
runnerctl add <target>
runnerctl list
runnerctl status [<target>]
runnerctl repair <target>
runnerctl remove <target>
runnerctl update runner [<target>|--all]
runnerctl update self
runnerctl agents init
```

This separates runner binary maintenance from CLI self-update and avoids overloading a bare `update` command.

## Output Recommendation

Default human output should be terse but complete:

- show planned changes before mutating local or GitHub state;
- use symbols plus words, not color alone;
- print remediation commands for every fail or warning in `doctor`;
- avoid job-log or run-history detail that duplicates GitHub Actions.

JSON output should be stable and boring:

```json
{
  "schemaVersion": 1,
  "command": "status",
  "ok": true,
  "runners": []
}
```

Each command can define command-specific fields, but the top-level envelope should be consistent.

## Takeaways

1. Reuse `gh` auth ergonomics, but build Runnerctl's own account selection because multi-identity local machines are common.
2. Keep `doctor` and `status` separate. Users need both: one for daily confidence, one for diagnosis.
3. Do not invent a new output language. Use human output plus `--json`.
4. Default to explicit target and scope handling. Names are cheap; ambiguous cleanup is expensive.
5. Make idempotency visible in output: say "already configured" instead of silently succeeding.
