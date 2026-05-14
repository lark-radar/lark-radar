#!/usr/bin/env bash
# Scan GitHub repos listed in projects.md and print JSON to stdout or --output FILE.
# Requires: gh, jq
# Usage:
#   scripts/lark-radar-scan.sh --since 2026-05-05
#   scripts/lark-radar-scan.sh --since 2026-05-05 --output reports/scan-2026-05-12.json

set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECTS_FILE="$ROOT_DIR/projects.md"
SINCE="$(date -u -d '7 days ago' +%F 2>/dev/null || date -v-7d +%F)"
COMMIT_LIMIT=100
ISSUE_LIMIT=20
PR_LIMIT=20
SLEEP_SECONDS="0.1"
OUTPUT_FILE=""

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
  --output FILE            Write JSON to file instead of stdout.
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
    --output) OUTPUT_FILE="$2"; shift 2 ;;
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

api_json_to_file() {
  local endpoint="$1"
  local output="$2"
  if ! gh api "$endpoint" > "$output" 2>/dev/null; then
    return 1
  fi
}

scan_one() {
  local repo="$1"
  local out_file="$2"
  local since_iso="${SINCE}T00:00:00Z"
  local repo_dir

  repo_dir="$(mktemp -d)"
  trap 'rm -rf "$repo_dir"' RETURN

  echo "scanning $repo" >&2

  if ! api_json_to_file "repos/$repo" "$repo_dir/repo.json"; then
    jq -n --arg repo "$repo" --arg error "repo_fetch_failed" \
      '{repo:{full_name:$repo}, error:$error, commits:[], issues:[], prs:[], activity:{commit_count:0, issue_count:0, pr_count:0}}' > "$out_file"
    return 0
  fi

  api_json_to_file "repos/$repo/commits?since=${since_iso}&per_page=${COMMIT_LIMIT}" "$repo_dir/commits.json" || echo '[]' > "$repo_dir/commits.json"
  api_json_to_file "repos/$repo/issues?state=all&sort=updated&direction=desc&per_page=${ISSUE_LIMIT}" "$repo_dir/issues.json" || echo '[]' > "$repo_dir/issues.json"
  api_json_to_file "repos/$repo/pulls?state=all&sort=updated&direction=desc&per_page=${PR_LIMIT}" "$repo_dir/prs.json" || echo '[]' > "$repo_dir/prs.json"

  jq -n \
    --arg since "$since_iso" \
    --slurpfile repo "$repo_dir/repo.json" \
    --slurpfile commits "$repo_dir/commits.json" \
    --slurpfile issues "$repo_dir/issues.json" \
    --slurpfile prs "$repo_dir/prs.json" '
    ($repo[0]) as $r |
    ($commits[0] // []) as $cs |
    ($issues[0] // []) as $is |
    ($prs[0] // []) as $ps |
    {
      repo: {
        full_name: $r.full_name,
        html_url: $r.html_url,
        description: $r.description,
        stars: $r.stargazers_count,
        forks: $r.forks_count,
        open_issues: $r.open_issues_count,
        language: $r.language,
        pushed_at: $r.pushed_at,
        updated_at: $r.updated_at,
        topics: ($r.topics // []),
        archived: $r.archived,
        disabled: $r.disabled,
        license: ($r.license.spdx_id // null)
      },
      commits: [
        $cs[]? | {
          sha: (.sha[0:7]),
          date: .commit.author.date,
          author: .commit.author.name,
          message: (.commit.message | split("\n")[0]),
          html_url: .html_url
        }
      ],
      issues: [
        $is[]?
        | select(.pull_request == null)
        | select(.updated_at >= $since)
        | {
          number, title, state, comments,
          created_at, updated_at, html_url,
          labels: [.labels[]?.name]
        }
      ],
      prs: [
        $ps[]?
        | select(.updated_at >= $since)
        | {
          number, title, state,
          created_at, updated_at, html_url,
          user: .user.login
        }
      ],
      activity: {
        commit_count: ($cs | length),
        issue_count: ([ $is[]? | select(.pull_request == null) | select(.updated_at >= $since) ] | length),
        pr_count: ([ $ps[]? | select(.updated_at >= $since) ] | length)
      }
    }' > "$out_file"
}

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

idx=0
for repo in "${REPOS[@]}"; do
  idx=$((idx + 1))
  echo "[$idx/${#REPOS[@]}] $repo" >&2
  scan_one "$repo" "$TMP_DIR/$idx.json" || \
    jq -n --arg repo "$repo" --arg error "scan_failed" \
      '{repo:{full_name:$repo}, error:$error, commits:[], issues:[], prs:[], activity:{commit_count:0, issue_count:0, pr_count:0}}' > "$TMP_DIR/$idx.json"
  sleep "$SLEEP_SECONDS"
done

if [[ -n "$OUTPUT_FILE" ]]; then
  mkdir -p "$(dirname "$OUTPUT_FILE")"
  jq -s \
    --arg generated_at "$(date -Iseconds)" \
    --arg since "$SINCE" \
    --arg projects_file "$PROJECTS_FILE" \
    '{generated_at:$generated_at, since:$since, projects_file:$projects_file, count:length, projects:.}' \
    "$TMP_DIR"/*.json > "$OUTPUT_FILE"
  echo "wrote $OUTPUT_FILE" >&2
else
  jq -s \
    --arg generated_at "$(date -Iseconds)" \
    --arg since "$SINCE" \
    --arg projects_file "$PROJECTS_FILE" \
    '{generated_at:$generated_at, since:$since, projects_file:$projects_file, count:length, projects:.}' \
    "$TMP_DIR"/*.json
fi
