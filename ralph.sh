#!/bin/bash
# Ralph Wiggum - long-running AI coding-agent loop
# Usage: ./ralph.sh [--tool amp|claude|omp] [max_iterations]

set -euo pipefail

TOOL="amp"
MAX_ITERATIONS=10

while [[ $# -gt 0 ]]; do
  case $1 in
    --tool)
      TOOL="$2"
      shift 2
      ;;
    --tool=*)
      TOOL="${1#*=}"
      shift
      ;;
    *)
      if [[ "$1" =~ ^[0-9]+$ ]]; then
        MAX_ITERATIONS="$1"
      fi
      shift
      ;;
  esac
done

if [[ "$TOOL" != "amp" && "$TOOL" != "claude" && "$TOOL" != "omp" ]]; then
  echo "Error: invalid tool '$TOOL'. Must be amp, claude, or omp."
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${RALPH_PROJECT_DIR:-$PWD}"
PRD_FILE="$SCRIPT_DIR/prd.json"
PROGRESS_FILE="$SCRIPT_DIR/progress.txt"
ARCHIVE_DIR="$SCRIPT_DIR/archive"
LAST_BRANCH_FILE="$SCRIPT_DIR/.last-branch"
STATE_DIR="$SCRIPT_DIR/state"
STATE_FILE="$STATE_DIR/iterations.jsonl"
LOCK_DIR="$SCRIPT_DIR/.ralph.lock"

if [[ ! -f "$PRD_FILE" ]]; then
  echo "Error: missing $PRD_FILE"
  exit 1
fi
if [[ ! -d "$PROJECT_DIR/.git" ]]; then
  echo "Error: RALPH_PROJECT_DIR must point to a git repository."
  exit 1
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq is required."
  exit 1
fi
if [[ "$TOOL" == "omp" ]] && ! command -v omp >/dev/null 2>&1; then
  echo "Error: omp is required for --tool omp."
  exit 1
fi
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  echo "Error: Ralph is already running ($LOCK_DIR exists)."
  exit 1
fi
trap 'rmdir "$LOCK_DIR"' EXIT INT TERM
mkdir -p "$ARCHIVE_DIR" "$STATE_DIR"

all_stories_pass() {
  jq -e '(.userStories | length > 0) and all(.userStories[]; .passes == true)' "$PRD_FILE" >/dev/null
}

if [[ -f "$LAST_BRANCH_FILE" ]]; then
  CURRENT_BRANCH=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || true)
  LAST_BRANCH=$(cat "$LAST_BRANCH_FILE" 2>/dev/null || true)
  if [[ -n "$CURRENT_BRANCH" && -n "$LAST_BRANCH" && "$CURRENT_BRANCH" != "$LAST_BRANCH" ]]; then
    DATE=$(date +%Y-%m-%d)
    FOLDER_NAME=$(echo "$LAST_BRANCH" | sed 's|^ralph/||')
    ARCHIVE_FOLDER="$ARCHIVE_DIR/$DATE-$FOLDER_NAME"
    mkdir -p "$ARCHIVE_FOLDER"
    cp "$PRD_FILE" "$ARCHIVE_FOLDER/"
    [[ -f "$PROGRESS_FILE" ]] && cp "$PROGRESS_FILE" "$ARCHIVE_FOLDER/"
    printf '# Ralph Progress Log\nStarted: %s\n---\n' "$(date -Iseconds)" > "$PROGRESS_FILE"
  fi
fi

CURRENT_BRANCH=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || true)
[[ -n "$CURRENT_BRANCH" ]] && printf '%s\n' "$CURRENT_BRANCH" > "$LAST_BRANCH_FILE"
[[ -f "$PROGRESS_FILE" ]] || printf '# Ralph Progress Log\nStarted: %s\n---\n' "$(date -Iseconds)" > "$PROGRESS_FILE"

if all_stories_pass; then
  echo "Ralph already complete."
  exit 0
fi

run_iteration() {
  case "$TOOL" in
    amp)
      cat "$SCRIPT_DIR/prompt.md" | amp --dangerously-allow-all 2>&1 | tee /dev/stderr || true
      ;;
    claude)
      claude --dangerously-skip-permissions --print < "$SCRIPT_DIR/CLAUDE.md" 2>&1 | tee /dev/stderr || true
      ;;
    omp)
      omp --cwd "$PROJECT_DIR" --no-session --approval-mode yolo -p "$(cat "$SCRIPT_DIR/OMP.md")" 2>&1 | tee /dev/stderr || true
      ;;
  esac
}

next_story_id() {
  jq -r '[.userStories[] | select(.passes == false)] | sort_by(.priority) | .[0].id // empty' "$PRD_FILE"
}

printf 'Starting Ralph — tool: %s, project: %s, max iterations: %s\n' "$TOOL" "$PROJECT_DIR" "$MAX_ITERATIONS"
for i in $(seq 1 "$MAX_ITERATIONS"); do
  printf '\n===============================================================\n'
  printf '  Ralph iteration %s of %s (%s)\n' "$i" "$MAX_ITERATIONS" "$TOOL"
  printf '===============================================================\n'

  STORY_ID_BEFORE=$(next_story_id)
  OUTPUT=$(run_iteration)
  if all_stories_pass; then
    jq -nc --arg timestamp "$(date -Iseconds)" --arg story_id "$STORY_ID_BEFORE" \
      '{timestamp: $timestamp, story_id: $story_id, status: "complete"}' >> "$STATE_FILE"
    printf '\nRalph completed all tasks at iteration %s.\n' "$i"
    exit 0
  fi
  STORY_ID_AFTER=$(next_story_id)
  STATUS="blocked"
  if [[ -n "$STORY_ID_BEFORE" && "$STORY_ID_BEFORE" != "$STORY_ID_AFTER" ]]; then
    STATUS="completed"
  fi
  jq -nc --arg timestamp "$(date -Iseconds)" --arg story_id "$STORY_ID_BEFORE" \
    --arg status "$STATUS" '{timestamp: $timestamp, story_id: $story_id, status: $status}' >> "$STATE_FILE"
  if echo "$OUTPUT" | grep -q '<promise>COMPLETE</promise>'; then
    echo "Warning: agent reported completion, but prd.json still has incomplete stories."
  fi
  printf 'Iteration %s complete. Continuing...\n' "$i"
  sleep 2
done

echo "Ralph reached max iterations ($MAX_ITERATIONS) without completing all tasks."
exit 1
