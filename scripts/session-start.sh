#!/usr/bin/env bash
set -euo pipefail

mode="${1:-}"

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

agent_mode="false"
if [[ "$mode" == "--agent" || -n "${CLAUDECODE:-}" || -n "${CLINE_ACTIVE:-}" || -n "${CURSOR_PROJECT_DIR:-}" || -n "${RUNNERHUB_AGENT:-}" ]]; then
  agent_mode="true"
fi

if [[ "$mode" == "--envrc" ]]; then
  echo "Runnerctl: read docs/00-context/agent-startup.md before work."
  exit 0
fi

if [[ "$agent_mode" == "true" ]]; then
  branch="$(git branch --show-current 2>/dev/null || true)"
  head="$(git rev-parse --short HEAD 2>/dev/null || true)"
  status_count="$(git status --porcelain | wc -l | tr -d ' ')"
  if [[ "$status_count" == "0" ]]; then
    dirty="false"
  else
    dirty="true"
  fi

  cat <<EOF
{"project":"runnerctl","branch":"$branch","head":"$head","dirty":$dirty,"changedFiles":$status_count,"read":["docs/00-context/agent-startup.md","docs/00-context/project-brief.md","docs/01-product/product-vision.md","docs/02-research/cli-ux-decisions.md","docs/04-operations/plans/product-roadmap.md"]}
EOF
  exit 0
fi

echo "Runnerctl session startup"
echo
echo "Read these first:"
echo "  1. docs/00-context/agent-startup.md"
echo "  2. docs/00-context/project-brief.md"
echo "  3. docs/01-product/product-vision.md"
echo
echo "Repository status:"
git status --short
