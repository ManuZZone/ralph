---
name: omp-ralph
description: Convert a Markdown PRD into prd.json for the OMP Ralph backend. Use when the user asks to prepare an OMP Ralph execution loop.
user-invocable: true
---

# OMP Ralph JSON Converter

Convert a PRD into `prd.json` adjacent to `ralph.sh`.

## Required schema

```json
{
  "project": "Project name",
  "branchName": "ralph/feature-name",
  "description": "Feature summary",
  "userStories": [
    {
      "id": "US-001",
      "title": "Short title",
      "description": "As a user, I want ... so that ...",
      "acceptanceCriteria": ["Observable criterion", "Verification command or scenario"],
      "priority": 1,
      "passes": false,
      "notes": ""
    }
  ]
}
```

## Rules

- Split work so each story is completable in one OMP iteration.
- Order by dependency.
- Keep `passes` false initially.
- Use verifiable acceptance criteria only.
- Add no automatic branch, commit, or AGENTS.md instructions.
- If replacing a PRD for a different feature, archive the previous `prd.json` and `progress.txt` under `archive/YYYY-MM-DD-<feature>/`.
