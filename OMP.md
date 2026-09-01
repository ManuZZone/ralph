# Ralph OMP Iteration Instructions

You are one fresh Oh My Pi coding-agent iteration. Work in the current project directory.

## Task

The launcher provides these absolute paths below:

```text
RALPH_PRD_FILE
RALPH_PROGRESS_FILE
```

1. Read `RALPH_PRD_FILE` and `RALPH_PROGRESS_FILE`.
2. Choose exactly one highest-priority user story with `passes: false`.
3. Implement only that story, following the project’s existing instructions and conventions.
4. Run the specific verification required by that story. Do not mark a story passing without evidence.
5. Update `RALPH_PRD_FILE` to set only the completed story’s `passes` value to `true`.
6. Append an entry to `RALPH_PROGRESS_FILE` with the story ID, implementation, verification, and concise reusable learnings.

## Constraints

- Do not create, change, or delete git branches.
- Do not commit changes.
- Do not automatically modify `AGENTS.md` or other repository instruction files.
- Do not work on more than one story in this iteration.
- If blocked, leave the story `passes: false`, record the blocker in `RALPH_PROGRESS_FILE`, and exit normally.
- `prd.json` is the source of truth. The loop validates completion from it directly.
- The launcher records iteration state; do not create or edit `state/iterations.jsonl`.

## Completion

If every `userStories[].passes` is `true`, end the response with:

<promise>COMPLETE</promise>
