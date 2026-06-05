# CLI UX Decisions

## Status

M0 decision gate. These decisions close the open questions from `cli-ux-research-plan.md` and `command-walkthroughs.md` unless marked "decide during implementation."

## Evidence Inputs

- `docs/02-research/cli-reference-audit.md`
- `docs/02-research/desk-research-findings.md`
- `docs/02-research/workflow-archaeology.md`
- `docs/02-research/command-walkthroughs.md`
- `docs/02-research/dogfood-journal.md`
- GitHub REST API for self-hosted runners: <https://docs.github.com/en/rest/actions/self-hosted-runners>
- GitHub self-hosted runner label docs: <https://docs.github.com/en/actions/how-tos/manage-runners/self-hosted-runners/use-in-a-workflow>

## Decision 1 - Command Set

Top-level commands:

```text
runnerctl login
runnerctl logout
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

Global flags:

```text
--json
--verbose
--dry-run
--yes
--profile <name>
--home <path>
```

Command-specific flags:

```text
login:
  --profile <name>
  --account <github-login>
  --hostname <host>
  --with-token
  --refresh

add:
  --scope repo|org
  --name <runner-name>
  --label <label>        # repeatable
  --no-machine-label
  --disable-runner-auto-update

list:
  --scope repo|org|all

status:
  --scope repo|org|all

repair:
  --strategy reinstall|service|state|github|interactive

remove:
  --keep-workspace
  --orphan

update runner:
  --all

agents init:
  --agent claude|codex|cursor|copilot|cline|aider|all
  --check
```

Rationale: the set matches the lifecycle promise without adding workflow scanning or job observability.

## Decision 2 - Auth Flow

Use a layered auth flow:

1. Reuse a valid `gh` CLI credential when present.
2. Fall back to OAuth device/browser login when no valid `gh` credential exists or the user chooses not to use it.
3. Support token input through `runnerctl login --with-token` for automation and constrained environments.
4. Respect `GITHUB_TOKEN`, `GH_TOKEN`, and `GH_HOST` for non-interactive use, but do not persist environment-provided tokens.

Runnerctl stores auth metadata in state but does not store raw tokens in `state.json`. Persistent secrets must live in the OS credential store or in `gh`'s existing credential store.

`login` must verify the specific operations Runnerctl needs for at least one repo/org target before claiming success. `add` must also verify target-specific permissions before mutating local state.

## Decision 3 - State Directory Location

Default home:

```text
~/.runnerctl
```

Override order:

1. `--home <path>`
2. `RUNNERCTL_HOME`
3. default `~/.runnerctl`

Directory layout:

```text
~/.runnerctl/
  state.json
  logs/
  cache/
  runners/
    <target-id>/
```

Rationale: Runnerctl owns both metadata and heavyweight runner workspaces. A single visible CLI-owned home is easier to inspect, back up, and repair than splitting state across XDG/Application Support paths and work directories.

## Decision 4 - Output Style

Human-readable output is the default. `--json` is available on every command.

Human output rules:

- plan before mutating;
- stream setup/removal/repair steps;
- use symbols plus words, not color alone;
- end with one concrete next action;
- keep detailed logs behind `--verbose`.

JSON output uses a stable envelope:

```json
{
  "schemaVersion": 1,
  "command": "status",
  "ok": true,
  "warnings": [],
  "errors": []
}
```

Each command adds command-specific fields. JSON mode never prompts; if required input is missing, it exits non-zero with a typed error.

## Decision 5 - Multi-Identity Handling

Support named profiles.

Default behavior:

- `runnerctl login` creates or refreshes the `default` profile.
- If multiple `gh` accounts are present, the user must choose one interactively or pass `--account`.
- Each registered target stores the profile that registered it.
- Commands that contact GitHub use the target's stored profile unless `--profile` is passed.

Rationale: personal repo plus work org is a core user scenario. One machine may have multiple GitHub identities, and stale inactive `gh` accounts are common enough to design for.

## Decision 6 - Default Labels

Use GitHub default labels plus one Runnerctl machine label.

macOS Apple Silicon:

```text
self-hosted, macOS, ARM64, <machine-label>
```

macOS Intel:

```text
self-hosted, macOS, x64, <machine-label>
```

Linux x86_64:

```text
self-hosted, linux, x64, <machine-label>
```

Linux ARM64:

```text
self-hosted, linux, ARM64, <machine-label>
```

The machine label defaults to a sanitized hostname with a short stable suffix if needed for uniqueness. Users can add labels with repeated `--label` flags and can suppress the machine label with `--no-machine-label`.

Output should recommend the precise label array including the machine label:

```yaml
runs-on: [self-hosted, macOS, ARM64, mac-mini-1]
```

Rationale: broad `runs-on: self-hosted` appears in the wild but is too easy to misroute once a machine has multiple runners or the account has other self-hosted capacity.

## Decision 7 - Idempotency Contract

Every command is safe to re-run.

| Command | Existing-state behavior |
| --- | --- |
| `login` | Refreshes or confirms profile. |
| `doctor` | Read-only; updates last-check metadata only. |
| `add` | If equivalent runner exists, no-op with "already configured." If config differs, print a reconfiguration plan and require confirmation unless `--yes`. |
| `list` | Read-only. |
| `status` | Read-only except status cache update. |
| `repair` | Re-applies the selected strategy. If no problem exists, no-op. |
| `remove` | If already absent locally and remotely, no-op. If one side remains, offer cleanup path. |
| `update runner` | If current, no-op. |
| `update self` | If current, no-op. |
| `agents init` | Creates or updates managed blocks only; never clobbers user content outside managed blocks. |

Partial installs must be represented in state so `repair` and `remove` can continue from failure rather than forcing manual deletion.

## Decision 8 - Error Message Template

Every actionable error follows this shape:

```text
Problem: <specific failure>
Cause:   <likely underlying cause>
Fix:     <copy-pasteable command or exact UI/API action>
Details: <only with --verbose, or one terse line by default>
```

Errors exposed in JSON include:

```json
{
  "code": "github.permission_missing",
  "message": "Repository admin access is required to register a runner.",
  "fix": "Run `runnerctl login --refresh` with an account that administers OWNER/REPO."
}
```

## Decision 9 - Doctor Checks

macOS checks for M1:

- OS and architecture support;
- launchd availability;
- disk free, warn below 50 GB, fail below 15 GB;
- command line tools installed;
- Xcode installed when requested or when Xcode-derived tools are detected as needed;
- Xcode license accepted;
- network reachability to `github.com` and `api.github.com`;
- TLS/certificate sanity through a real HTTPS request;
- runner binary present and supported version if any runner exists;
- each runner directory exists;
- each launchd service exists and is loaded;
- GitHub sees each runner and reports expected labels.

Linux checks for M4:

- OS and architecture support;
- systemd availability;
- glibc compatibility with current runner binary;
- disk free with same thresholds;
- network reachability to `github.com` and `api.github.com`;
- runner binary present and supported version if any runner exists;
- each runner directory exists;
- each systemd unit exists, is enabled, and is active;
- GitHub sees each runner and reports expected labels.

Severity:

- `info`: useful fact;
- `warn`: likely future issue or degraded condition;
- `fail`: expected to block runner setup or job execution.

Every warn/fail includes a fix.

## Decision 10 - Runner Self-Update Model

Runner binary updates are explicit:

```text
runnerctl update runner <target>
runnerctl update runner --all
```

By default, use the official runner's automatic update behavior unless the user passes `--disable-runner-auto-update` during `add`. Even with auto-update enabled, `doctor` and `status` should report stale or unsupported versions because runner update behavior can fail.

`runnerctl update self` updates the Runnerctl CLI, not runner binaries.

Rationale: the command name must distinguish "update GitHub runner software" from "update this CLI."

## Decision 11 - Default Confirmation Strategy

Use confirmation when a command mutates GitHub state, local services, or runner directories.

- `add`: print plan and default to yes in interactive mode.
- `remove`: print deletion plan and default to no.
- `repair`: prompt when strategy is ambiguous; no prompt when `--strategy` is provided.
- `update runner`: default to yes for one target, require `--all` for fleet-wide updates.

`--yes` skips prompts. `--json` never prompts and requires enough flags to proceed.

## Decision 12 - Ambiguous Target Disambiguation

Target forms:

```text
owner/repo       # repository target
org             # organization target, unless ambiguous
```

If a one-segment target could refer to both a user and an organization, require:

```text
--scope org
```

Repository targets are always two-segment `owner/repo`. Do not support implicit "current git remote repo" in M1; it can be added later only if it does not make `add` surprising.

## Decision 13 - Recent Job Count In `list`

Out of scope.

`list` shows:

- target;
- scope;
- runner name;
- profile;
- labels;
- GitHub online/offline/busy status when available;
- local service status.

It does not show `JOBS(24h)` or job history. That belongs in GitHub Actions or a future different product.

## Decision 14 - Status Exit Codes

Exit codes:

```text
0  all requested runners healthy
1  one or more requested runners unhealthy, or host check fails
2  usage/configuration error
3  GitHub/network unavailable, status incomplete
```

If some runners are healthy and others are not, `status` exits `1`. JSON mode includes per-runner statuses so scripts can decide whether partial health is acceptable.

## Decision 15 - Failed Deregistration Handling

`remove` proceeds in this order:

1. stop local service;
2. attempt graceful runner removal with a remove token;
3. if graceful removal fails, attempt GitHub forced delete when the runner ID is known and credentials allow it;
4. remove local service definition;
5. remove or keep workspace according to flags;
6. update local state.

If GitHub-side cleanup fails, Runnerctl completes local cleanup only after warning clearly and recording an orphaned remote cleanup task in state. Output prints the exact `runnerctl remove <target> --orphan` or GitHub API follow-up path.

## Decision 16 - Repair Failure-Mode Catalog

M1/M2 `repair` must handle:

- missing runner directory referenced by state;
- missing runner binary;
- corrupted or missing service file;
- service installed but not loaded/enabled;
- service loaded but stopped/exited;
- local state references a GitHub runner that no longer exists;
- GitHub runner exists but labels differ from state;
- stale or unsupported runner binary;
- partial `add` failure after token minting;
- profile credential expired or missing permission.

M3 expands repair for multi-target org scenarios and runner updates across all targets.

## Decision 17 - Interactive Defaults Vs Flags

Interactive by default for humans; flag-complete for scripts.

Rules:

- If stdin is a TTY and `--json` is not set, prompts are allowed for confirmation or strategy choice.
- If stdin is not a TTY, commands must either have enough flags or fail with a fix.
- `--dry-run` prints the planned operations and exits without mutation.
- `--json --dry-run` returns the same plan as structured data.

## Decision 18 - Update Semantics

`runnerctl update` has subcommands only:

```text
runnerctl update runner
runnerctl update self
```

A bare `runnerctl update` prints help and exits with usage code `2`.

Rationale: overloading one `update` command would be ambiguous and risky once Runnerctl itself is distributed through Homebrew/tarballs while runner binaries are downloaded from GitHub.

## Additional M1 Implementation Notes

These are not CLI UX decisions, but they should steer the first implementation pass:

- Choose an implementation language in M1 with bias toward a single static-ish binary, good OS service integration, and easy JSON testing.
- Do not implement workflow YAML scanning.
- Treat public repositories and fork-PR workflows as safety warnings in `add` and `doctor`.
- Test idempotency by running lifecycle commands twice in acceptance tests.

## M0 Exit Assessment

M0 is complete when this document, the research artifacts, and the architecture/status doc updates land together. Hardware dogfooding remains ongoing and feeds M1/M2 acceptance, but it no longer blocks implementation scaffolding.
