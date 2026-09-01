#!/bin/bash
# Create an isolated OMP Ralph run from a target repository and task description.

set -euo pipefail

PROJECT_DIR=""
TASK=""
MAX_ITERATIONS=10
PLAN_TIMEOUT_SECONDS=180
DRY_RUN=false

usage() {
  cat <<'EOF'
Usage:
  ./tools/init-omp-run.sh --project /path/to/repo --task "what to do" [--iterations N] [--plan-timeout seconds] [--dry-run]

Creates an isolated run under runs/ and asks OMP to write its prd.json.
The target repository is not modified during initialization. Run the printed
command explicitly to start implementation.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project)
      PROJECT_DIR="$2"
      shift 2
      ;;
    --task)
      TASK="$2"
      shift 2
      ;;
    --iterations)
      MAX_ITERATIONS="$2"
      shift 2
      ;;
    --plan-timeout)
      PLAN_TIMEOUT_SECONDS="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Error: unknown option '$1'." >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "$PROJECT_DIR" || -z "$TASK" ]]; then
  echo "Error: --project and --task are required." >&2
  usage >&2
  exit 1
fi
if [[ ! "$MAX_ITERATIONS" =~ ^[1-9][0-9]*$ ]]; then
  echo "Error: --iterations must be a positive integer." >&2
  exit 1
fi
if [[ ! "$PLAN_TIMEOUT_SECONDS" =~ ^[1-9][0-9]*$ ]]; then
  echo "Error: --plan-timeout must be a positive integer." >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq is required." >&2
  exit 1
fi
if ! command -v omp >/dev/null 2>&1; then
  echo "Error: omp is required." >&2
  exit 1
fi

PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"
if [[ ! -d "$PROJECT_DIR/.git" ]]; then
  echo "Error: --project must point to a git repository." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SLUG="$(printf '%s' "$TASK" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/^-//; s/-$//' | cut -c1-48)"
[[ -n "$SLUG" ]] || SLUG="omp-run"
RUN_DIR="$SCRIPT_DIR/runs/$(date +%Y%m%d-%H%M%S)-$SLUG"

if [[ "$DRY_RUN" == true ]]; then
  printf 'project=%s\nrun_dir=%s\niterations=%s\ntask=%s\n' "$PROJECT_DIR" "$RUN_DIR" "$MAX_ITERATIONS" "$TASK"
  exit 0
fi

mkdir -p "$RUN_DIR/state"
cp "$SCRIPT_DIR/ralph.sh" "$RUN_DIR/ralph.sh"
cp "$SCRIPT_DIR/OMP.md" "$RUN_DIR/OMP.md"
chmod +x "$RUN_DIR/ralph.sh"
printf '# Ralph Progress Log\nStarted: %s\n---\n' "$(date -Iseconds)" > "$RUN_DIR/progress.txt"

BOOTSTRAP_PROMPT=$(cat <<EOF
You are preparing an Oh My Pi Ralph run. Do not edit the target repository.

Target repository: $PROJECT_DIR
Run directory: $RUN_DIR
Task request: $TASK

Create exactly one valid JSON file at $RUN_DIR/prd.json using the Ralph schema:
- project: the target repository name
- branchName: ralph/<short-kebab-feature-name>
- description: concise summary of the task request
- userStories: ordered, small, independently verifiable stories
- create at most 5 user stories
- each story has id, title, description, acceptanceCriteria, priority, passes=false, notes=""
- priority is a JSON integer: 1 for the first story, then 2, 3, and so on. Never use words such as "high".

Planning budget: inspect at most 12 relevant files or search results. Reuse established page, filtering, download-service, and PDF-plugin patterns. Do not deeply explore unrelated code. Break large work into one-story-per-fresh-session units. Include specific verification in each story. Do not create branches, commits, source files, AGENTS.md edits, or any other target-repository changes. Reply only after writing the JSON file.
EOF
)

omp --cwd "$PROJECT_DIR" --no-session --approval-mode yolo --max-time "$PLAN_TIMEOUT_SECONDS" -p "$BOOTSTRAP_PROMPT"
if ! jq -e '(.project | type == "string") and (.branchName | type == "string") and (.description | type == "string") and (.userStories | type == "array" and length > 0 and length <= 5) and all(.userStories[]; (.id | type == "string") and (.title | type == "string") and (.description | type == "string") and (.acceptanceCriteria | type == "array" and length > 0 and all(.[]; type == "string")) and (.priority | type == "number" and floor == . and . > 0) and (.passes | type == "boolean" and . == false) and (.notes | type == "string"))' "$RUN_DIR/prd.json" >/dev/null; then
  echo "Error: OMP did not create a valid prd.json at $RUN_DIR/prd.json." >&2
  exit 1
fi

cat <<EOF

OMP Ralph run created:
  $RUN_DIR

Review the generated PRD:
  jq . "$RUN_DIR/prd.json"

Start the loop explicitly:
  RALPH_PROJECT_DIR="$PROJECT_DIR" "$RUN_DIR/ralph.sh" --tool omp $MAX_ITERATIONS
EOF
