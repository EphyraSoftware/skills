# PLAN.md Format Reference

A `PLAN.md` file has three sections: a preamble, optional design references, and a task list.

```markdown
# Plan: [Name]

## Overview
What this plan is for and why — the "what" and the goals.
Scope, key constraints, and any important decisions already made.

## Design References
- `docs/architecture.md`
- Or a link / external pointer

## Tasks
- [ ] 1. Short task title
  - Constraint or goal for this task
  - Another note or pointer

- [ ] 2. Next task title
  - ...
```

## Task format

Tasks use standard markdown checkboxes (`- [ ]` / `- [x]`). Number them for clarity. Tasks are executed in order — do not skip a task unless explicitly instructed. Sub-bullets provide constraints, goals, and pointers specific to that task. If a task has no sub-bullets, rely on the task title, plan overview, and codebase context.

## Completion tracking

Mark tasks complete by updating the checkbox to `- [x]` in `PLAN.md` as each task finishes. This makes progress resilient to session restarts.
