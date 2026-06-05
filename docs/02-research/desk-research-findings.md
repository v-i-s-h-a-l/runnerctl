# Desk Research Findings

## Purpose

Capture current GitHub self-hosted runner mechanics, recurring setup pain points, and product risks that should shape Runnerctl's M0 CLI decisions.

## Sources

- GitHub REST API for self-hosted runners: <https://docs.github.com/en/rest/actions/self-hosted-runners>
- GitHub workflow label guidance: <https://docs.github.com/en/actions/how-tos/manage-runners/self-hosted-runners/use-in-a-workflow>
- GitHub runner selection guidance: <https://docs.github.com/en/actions/how-tos/write-workflows/choose-where-workflows-run/choose-the-runner-for-a-job>
- GitHub self-hosted runner communications/update reference: <https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/communicating-with-self-hosted-runners>
- GitHub runner minimum-version changelog, March 13, 2026: <https://github.blog/changelog/2026-03-13-self-hosted-runner-minimum-version-enforcement-paused/>
- GitHub Actions 2026 pricing update: <https://github.com/resources/insights/2026-pricing-changes-for-github-actions>
- GitHub Community discussion on fine-grained PAT confusion: <https://github.com/orgs/community/discussions/120232>
- GitHub Community discussion on label enforcement: <https://github.com/orgs/community/discussions/184728>
- GitHub Community discussion on unregister failures: <https://github.com/orgs/community/discussions/172483>

## Runner Mechanics That Matter

GitHub exposes separate REST endpoints for organization and repository runners. Both scopes support listing runners, creating registration tokens, creating remove tokens, deleting runners, and managing labels. Registration and remove tokens expire after one hour.

Permission requirements differ by scope:

- Repository runner APIs require repository admin access. Classic PATs need `repo` for private repositories. Fine-grained tokens need repository Administration write permission for registration/removal.
- Organization runner APIs require organization admin access. Classic PATs need `admin:org`, plus `repo` for private repository access where applicable. Fine-grained tokens need organization Self-hosted runners permission.

Default labels are applied at configuration time:

- `self-hosted`
- OS label: `linux`, `windows`, or `macOS`
- architecture label: `x64`, `ARM`, or `ARM64`

Workflow matching is cumulative: a runner must match all labels in the `runs-on` array. GitHub recommends self-hosted label arrays that begin with `self-hosted`.

Runner updates are operationally important. GitHub's public messaging around minimum-version enforcement changed in 2026, but the current direction remains clear: stale runners eventually stop registering or executing jobs. Runnerctl should not leave updates to chance.

## Pain-Point Clusters

### Auth And Permissions

Users struggle to map "I can access this repo/org" to the exact token permission required for runner registration. Fine-grained PAT behavior is especially confusing because permission names and API failure messages are not always intuitive.

Implication: `login` and `add` must test the exact endpoint they will use and report the missing permission in plain English.

### Registration Token Expiry

Registration and remove tokens expire quickly. This is fine for a single manual setup, but awkward for automation and repair flows.

Implication: Runnerctl should mint tokens just-in-time, never store them, and make retry behavior explicit.

### Label Routing

Labels are both the routing primitive and a safety boundary. Users can accidentally create broad runners that pick up jobs they did not intend. GitHub discussions also show concern that labels are not a strong enforcement mechanism by themselves.

Implication: Runnerctl should keep default GitHub labels, add a stable machine label by default, and warn when organization-scope runners have no custom narrowing label.

### Service Installation

The official runner scripts can install services, but users still have to understand launchd/systemd, work directories, logs, and process state. Failures often surface as "runner online but not taking jobs" or "service exited" rather than a crisp root cause.

Implication: `status` should check both GitHub-side status and local service status. `doctor` should group local host, service, and GitHub checks.

### Unregister And Cleanup

Removing runners can fail when token permissions are wrong, the runner directory is missing, or the GitHub-side runner is stale. GitHub exposes a forced delete endpoint for stale runners.

Implication: local cleanup should be able to proceed even if GitHub deregistration fails, but output must print the exact follow-up command/API action needed to clean up GitHub-side state.

### Pricing Volatility

GitHub announced a 2026 cloud platform charge for self-hosted runner usage, then postponed that self-hosted billing change to re-evaluate it. Current billing documentation still says self-hosted runner usage is free, but the announcement makes the pricing environment unstable.

Implication: Runnerctl's value proposition should be framed as cost control plus local control and macOS capacity, not as a permanent promise of zero GitHub-side cost.

## Product Decisions Supported By This Research

1. Prefer `gh` auth reuse, but verify endpoint access during `login`/`add`.
2. Keep registration/remove tokens ephemeral and invisible to local state.
3. Apply labels: GitHub defaults plus one stable machine label. Encourage custom labels for org runners.
4. Make `status` compare local service state with GitHub runner state.
5. Make `repair` a first-class command because drift is normal: local state, GitHub state, service state, and runner binary version can diverge.
6. Avoid recent job analytics in `list`; this drifts into observability. Show `busy`, `online/offline`, labels, scope, and service status instead.
