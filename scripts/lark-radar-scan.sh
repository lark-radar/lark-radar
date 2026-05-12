#!/usr/bin/env bash
# Scan GitHub repos listed in projects.md and print JSON to stdout.
# Requires: gh, jq
# Usage:
#   scripts/lark-radar-scan.sh --since 2026-05-05
#   scripts/lark-radar-scan.sh --projects projects.md --since 2026-05-05

set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECTS_FILE="$ROOT_DIR/projects.md"
SINCE="$(date -u -d '7 days ago' +%F 2>/dev/null || date -v-7d +%F)"
COMMIT_LIMIT=100
ISSUE_LIMIT=20
PR_LIMIT=20
SLEEP_SECONDS="0.1"

usage() {
  cat <<EOF
Usage: $0 [options]

Options:
  --since YYYY-MM-DD       Start date for activity window. Default: 7 days ago.
  --projects FILE          Markdown project list. Default: $PROJECTS_FILE
  --commit-limit N         Max commits fetched per repo. Default: $COMMIT_LIMIT
  --issue-limit N          Max issues fetched per repo. Default: $ISSUE_LIMIT
  --pr-limit N             Max PRs fetched per repo. Default: $PR_LIMIT
  --sleep SECONDS          Sleep between repos. Default: $SLEEP_SECONDS
  -h, --help               Show help.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --since) SINCE="$2"; shift 2 ;;
    --projects) PROJECTS_FILE="$2"; shift 2 ;;
    --commit-limit) COMMIT_LIMIT="$2"; shift 2 ;;
    --issue-limit) ISSUE_LIMIT="$2"; shift 2 ;;
    --pr-limit) PR_LIMIT="$2"; shift 2 ;;
    --sleep) SLEEP_SECONDS="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if ! command -v gh >/dev/null 2>&1; then
  echo "gh CLI is required" >&2
  exit 127
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required" >&2
  exit 127
fi

if [[ ! -f "$PROJECTS_FILE" ]]; then
  echo "projects file not found: $PROJECTS_FILE" >&2
  exit 1
fi

mapfile -t REPOS < <(
  grep -Eo 'github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+' "$PROJECTS_FILE" \
    | sed 's#github.com/##' \
    | sed 's#[).,]*$##' \
    | sort -u
)

if [[ ${#REPOS[@]} -eq 0 ]]; then
  echo "no repositories found in $PROJECTS_FILE" >&2
  exit 1
fi

api_json() {
  local endpoint="$1"
  gh api "$endpoint" 2>/dev/null
}

scan_one() {
  local repo="$1"
  local since_iso="${SINCE}T00:00:00Z"
  echo "scanning $repo" >&2

  local repo_json commits_json issues_json prs_json error_json

  repo_json="$(api_json "repos/$repo")"
  if [[ -z "$repo_json" ]]; then
    jq -n --arg repo "$repo" --arg error "repo_fetch_failed" '{repo:{full_name:$repo}, error:$error, commits:[], issues:[], prs:[]}'
    return 0
  fi

  commits_json="$(api_json "repos/$repo/commits?since=${since_iso}&per_page=${COMMIT_LIMIT}")"
  [[ -n "$commits_json" ]] || commits_json='[]'

  issues_json="$(api_json "repos/$repo/issues?state=all&sort=updated&direction=desc&per_page=${ISSUE_LIMIT}")"
  [[ -n "$issues_json" ]] || issues_json='[]'

  prs_json="$(api_json "repos/$repo/pulls?state=all&sort=updated&direction=desc&per_page=${PR_LIMIT}")"
  [[ -n "$prs_json" ]] || prs_json='[]'

  jq -n \
    --arg since "$since_iso" \
    --argjson repo "$repo_json" \
    --argjson commits "$commits_json" \
    --argjson issues "$issues_json" \
    --argjson prs "$prs_json" '
    {
      repo: {
        full_name: $repo.full_name,
        html_url: $repo.html_url,
        description: $repo.description,
        stars: $repo.stargazers_count,
        forks: $repo.forks_count,
        open_issues: $repo.open_issues_count,
        language: $repo.language,
        pushed_at: $repo.pushed_at,
        updated_at: $repo.updated_at,
        topics: ($repo.topics // []),
        archived: $repo.archived,
        disabled: $repo.disabled,
        license: ($repo.license.spdx_id // null)
      },
      commits: [
        $commits[]? | {
          sha: (.sha[0:7]),
          date: .commit.author.date,
          author: .commit.author.name,
          message: (.commit.message | split("\n")[0]),
          html_url: .html_url
        }
      ],
      issues: [
        $issues[]?
        | select(.pull_request == null)
        | select(.updated_at >= $since)
        | {
          number, title, state, comments,
          created_at, updated_at, html_url,
          labels: [.labels[]?.name]
        }
      ],
      prs: [
        $prs[]?
        | select(.updated_at >= $since)
        | {
          number, title, state,
          created_at, updated_at, html_url,
          user: .user.login
        }
      ],
      activity: {
        commit_count: ($commits | length),
        issue_count: ([ $issues[]? | select(.pull_request == null) | select(.updated_at >= $since) ] | length),
        pr_count: ([ $prs[]? | select(.updated_at >= $since) ] | length)
      }
    }'
}

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

printf '%s\n' "${REPOS[@]}" > "$TMP_DIR/repos.txt"

idx=0
for repo in "${REPOS[@]}"; do
  idx=$((idx + 1))
  echo "[$idx/${#REPOS[@]}] $repo" >&2
  scan_one "$repo" > "$TMP_DIR/$idx.json" || \
    jq -n --arg repo "$repo" --arg error "scan_failed" '{repo:{full_name:$repo}, error:$error, commits:[], issues:[], prs:[], activity:{commit_count:0, issue_count:0, pr_count:0}}' > "$TMP_DIR/$idx.json"
  sleep "$SLEEP_SECONDS"
done

jq -s \
  --arg generated_at "$(date -Iseconds)" \
  --arg since "$SINCE" \
  --arg projects_file "$PROJECTS_FILE" \
  '{generated_at:$generated_at, since:$since, projects_file:$projects_file, count:length, projects:.}' \
  "$TMP_DIR"/*.json
