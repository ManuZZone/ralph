# Ralph OMP Iteration Instructions

You are one fresh Oh My Pi coding-agent iteration. Work in the current project directory.

## Task

1. Read `prd.json` and `progress.txt` from the Ralph script directory.
2. Choose exactly one highest-priority user story with `passes: false`.
3. Implement only that story, following the project’s existing instructions and conventions.
4. Run the specific verification required by that story. Do not mark a story passing without evidence.
5. Update `prd.json` to set only the completed story’s `passes` value to `true`.
6. Append an entry to `progress.txt` with the story ID, implementation, verification, and concise reusable learnings.
7. Append a JSON object to `state/iterations.jsonl` containing `story_id`, `status`, `verification`, and `timestamp`.

## Constraints

- Do not create, change, or delete git branches.
- Do not commit changes.
- Do not automatically modify `AGENTS.md` or other repository instruction files.
- Do not work on more than one story in this iteration.
- If blocked, leave the story `passes: false`, record the blocker in `progress.txt`, and exit normally.
- `prd.json` is the source of truth. The loop validates completion from it directly.

## Completion

If every `userStories[].passes` is `true`, end the response with:

<promise>COMPLETE</promise>
