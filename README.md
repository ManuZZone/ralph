# Ralph

![Ralph](ralph.webp)

Ralph is an autonomous AI agent loop that runs AI coding tools ([Amp](https://ampcode.com) or [Claude Code](https://docs.anthropic.com/en/docs/claude-code)) repeatedly until all PRD items are complete. Each iteration is a fresh instance with clean context. Memory persists via git history, `progress.txt`, and `prd.json`.

Based on [Geoffrey Huntley's Ralph pattern](https://ghuntley.com/ralph/).

[Read my in-depth article on how I use Ralph](https://x.com/ryancarson/status/2008548371712135632)

## Prerequisites

- One of the following AI coding tools installed and authenticated:
  - [Amp CLI](https://ampcode.com) (default)
  - [Claude Code](https://docs.anthropic.com/en/docs/claude-code) (`npm install -g @anthropic-ai/claude-code`)
- `jq` installed (`brew install jq` on macOS)
- A git repository for your project

## Setup

### Option 1: Copy to your project

Copy the ralph files into your project:

```bash
# From your project root
mkdir -p scripts/ralph
cp /path/to/ralph/ralph.sh scripts/ralph/

## Copy the prompt template for your AI tool of choice:
cp /path/to/ralph/prompt.md scripts/ralph/prompt.md    # For Amp
# OR
cp /path/to/ralph/CLAUDE.md scripts/ralph/CLAUDE.md    # For Claude Code
# OR
cp /path/to/ralph/OMP.md scripts/ralph/OMP.md          # For Oh My Pi
chmod +x scripts/ralph/ralph.sh
```

### Option 2: Install skills globally (Amp)

Copy the skills to your Amp or Claude config for use across all projects:

For AMP
```bash
cp -r skills/prd ~/.config/amp/skills/
cp -r skills/ralph ~/.config/amp/skills/
```

For Claude Code (manual)
```bash
cp -r skills/prd ~/.claude/skills/
cp -r skills/ralph ~/.claude/skills/
```

### Option 3: Use as Claude Code Marketplace

Add the Ralph marketplace to Claude Code:

```bash
/plugin marketplace add snarktank/ralph
```

Then install the skills:

```bash
/plugin install ralph-skills@ralph-marketplace
```

Available skills after installation:
- `/prd` - Generate Product Requirements Documents
- `/ralph` - Convert PRDs to prd.json format

Skills are automatically invoked when you ask Claude to:
- "create a prd", "write prd for", "plan this feature"
- "convert this prd", "turn into ralph format", "create prd.json"

### Configure Amp auto-handoff (recommended)

Add to `~/.config/amp/settings.json`:

```json
{
  "amp.experimental.autoHandoff": { "context": 90 }
}
```

This enables automatic handoff when context fills up, allowing Ralph to handle large stories that exceed a single context window.

## Workflow

### 1. Create a PRD

Use the PRD skill to generate a detailed requirements document:

```
Load the prd skill and create a PRD for [your feature description]
```

Answer the clarifying questions. The skill saves output to `tasks/prd-[feature-name].md`.

### 2. Convert PRD to Ralph format

Use the Ralph skill to convert the markdown PRD to JSON:

```
Load the ralph skill and convert tasks/prd-[feature-name].md to prd.json
```

This creates `prd.json` with user stories structured for autonomous execution.

### 3. Run Ralph

```bash
# Using Amp (default)
./scripts/ralph/ralph.sh [max_iterations]

# Using Claude Code
./scripts/ralph/ralph.sh --tool claude [max_iterations]

# Using Oh My Pi
RALPH_PROJECT_DIR=/path/to/your/project ./scripts/ralph/ralph.sh --tool omp [max_iterations]
```

Default is 10 iterations. Use `--tool amp`, `--tool claude`, or `--tool omp` to select your AI coding tool.

Amp and Claude Code runs follow the upstream branch/commit behavior. The OMP backend instead:

1. Picks the highest priority story where `passes: false`
2. Implements exactly that story
3. Runs the story’s specific verification
4. Updates `prd.json` only after verification passes
5. Appends learnings to `progress.txt`
6. Records iteration state in `state/iterations.jsonl`
7. Repeats until all stories pass or max iterations is reached

### Oh My Pi backend

The `omp` backend runs a fresh non-interactive Oh My Pi session for each iteration. It requires `omp` and `jq` on `PATH`.

`RALPH_PROJECT_DIR` selects the git repository to modify; it defaults to the launch directory. Unlike the upstream Amp and Claude prompts, `OMP.md` does not create branches or commits and does not automatically edit `AGENTS.md`. `prd.json` is the completion source of truth.

### OMP skills

Copy the OMP-native skills into your project or global OMP skill directory:

```bash
mkdir -p ~/.omp/agent/skills
cp -r skills/omp-prd ~/.omp/agent/skills/
cp -r skills/omp-ralph ~/.omp/agent/skills/
```

Use `/omp-prd` to create a one-story-per-iteration PRD and `/omp-ralph` to create `prd.json` before launching `ralph.sh --tool omp`.




### Start an OMP run

Create an isolated Ralph run from a target git repository and a plain-language task request:

```bash
./tools/init-omp-run.sh \
  --project /path/to/project \
  --task "Implement and verify the selected feature" \
  --iterations 5
```

Initialization uses OMP only to create `runs/<timestamp>-<task>/prd.json`; it does not edit, branch, or commit the target repository. Review the generated PRD, then run the command printed by the bootstrap script to begin implementation.


## Key Files

| File | Purpose |
|------|---------|
| `ralph.sh` | The bash loop that spawns fresh AI instances (supports `--tool amp`, `--tool claude`, or `--tool omp`) |
| `prompt.md` | Prompt template for Amp |
| `CLAUDE.md` | Prompt template for Claude Code |
| `OMP.md` | Prompt template for Oh My Pi |
| `prd.json` | User stories with `passes` status (the task list) |
| `prd.json.example` | Example PRD format for reference |
| `progress.txt` | Append-only learnings for future iterations |
| `skills/prd/` | Skill for generating PRDs (works with Amp and Claude Code) |
| `skills/ralph/` | Skill for converting PRDs to JSON (works with Amp and Claude Code) |
| `.claude-plugin/` | Plugin manifest for Claude Code marketplace discovery |
| `flowchart/` | Interactive visualization of how Ralph works |

## Flowchart

[![Ralph Flowchart](ralph-flowchart.png)](https://snarktank.github.io/ralph/)

**[View Interactive Flowchart](https://snarktank.github.io/ralph/)** - Click through to see each step with animations.

The `flowchart/` directory contains the source code. To run locally:

```bash
cd flowchart
npm install
npm run dev
```

## Critical Concepts

### Each Iteration = Fresh Context

Each iteration spawns a **new AI instance** (Amp or Claude Code) with clean context. The only memory between iterations is:
- Git history (commits from previous iterations)
- `progress.txt` (learnings and context)
- `prd.json` (which stories are done)

### Small Tasks

Each PRD item should be small enough to complete in one context window. If a task is too big, the LLM runs out of context before finishing and produces poor code.

Right-sized stories:
- Add a database column and migration
- Add a UI component to an existing page
- Update a server action with new logic
- Add a filter dropdown to a list

Too big (split these):
- "Build the entire dashboard"
- "Add authentication"
- "Refactor the API"

### AGENTS.md Updates Are Critical

After each iteration, Ralph updates the relevant `AGENTS.md` files with learnings. This is key because AI coding tools automatically read these files, so future iterations (and future human developers) benefit from discovered patterns, gotchas, and conventions.

Examples of what to add to AGENTS.md:
- Patterns discovered ("this codebase uses X for Y")
- Gotchas ("do not forget to update Z when changing W")
- Useful context ("the settings panel is in component X")

### Feedback Loops

Ralph only works if there are feedback loops:
- Typecheck catches type errors
- Tests verify behavior
- CI must stay green (broken code compounds across iterations)

### Browser Verification for UI Stories

Frontend stories must include "Verify in browser using dev-browser skill" in acceptance criteria. Ralph will use the dev-browser skill to navigate to the page, interact with the UI, and confirm changes work.

### Stop Condition

When all stories have `passes: true`, Ralph outputs `<promise>COMPLETE</promise>` and the loop exits.

## Debugging

Check current state:

```bash
# See which stories are done
cat prd.json | jq '.userStories[] | {id, title, passes}'

# See learnings from previous iterations
cat progress.txt

# Check git history
git log --oneline -10
```

## Customizing the Prompt

After copying `prompt.md` (for Amp) or `CLAUDE.md` (for Claude Code) to your project, customize it for your project:
- Add project-specific quality check commands
- Include codebase conventions
- Add common gotchas for your stack

## Archiving

Ralph automatically archives previous runs when you start a new feature (different `branchName`). Archives are saved to `archive/YYYY-MM-DD-feature-name/`.

## References

- [Geoffrey Huntley's Ralph article](https://ghuntley.com/ralph/)
- [Amp documentation](https://ampcode.com/manual)
- [Claude Code documentation](https://docs.anthropic.com/en/docs/claude-code)
