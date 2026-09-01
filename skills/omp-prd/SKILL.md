---
name: omp-prd
description: Create a Ralph PRD for an Oh My Pi iteration loop. Use when the user asks to create a PRD or plan work for the OMP Ralph backend.
user-invocable: true
---

# OMP Ralph PRD

Create a concise Markdown PRD suitable for one-story-per-iteration OMP execution.

## Process

1. Ask only material clarification questions using OMP's `ask` tool.
2. Create `tasks/prd-<feature-name>.md`.
3. Do not implement any story.

## Required PRD content

- Overview and explicit non-goals.
- Ordered user stories named `US-001`, `US-002`, and so on.
- Each story must fit one fresh OMP session.
- Every acceptance criterion must be observable and verifiable.
- UI stories must require browser verification.
- Include the exact targeted verification command or scenario where known.

Do not add checkboxes to the PRD. Do not prescribe git branches, commits, or instruction-file updates.
