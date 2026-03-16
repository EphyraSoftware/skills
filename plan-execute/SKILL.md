---
name: plan-execute
description: "Structured, iterative execution of a coding plan from a PLAN.md file. Implements tasks one at a time with a multi-step check chain (build/test, coverage, design review, consistency) and stall detection. Use when a PLAN.md file is present in the working directory and the task is to implement it. Triggers on: 'work through the plan', 'execute the plan', 'implement the plan', or any request to proceed with PLAN.md tasks."
---

# Plan Execute

Work through a `PLAN.md` file task by task, with a disciplined check chain after each implementation to catch issues before moving on.

## Prerequisites

A `PLAN.md` must exist in the working directory. If absent, stop and tell the user.

Design and architecture documentation must be locatable — either within the repository (e.g. `docs/`, `ARCHITECTURE.md`, `DESIGN.md`, ADR files) or referenced from a `CLAUDE.md` / `AGENTS.md` steering file. If none is found, note it and proceed using code-level inference for the design review step.

## PLAN.md Format

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

Tasks use standard markdown checkboxes (`- [ ]` / `- [x]`). Number them for clarity. Sub-bullets provide constraints, goals, and pointers specific to that task — read them before implementing.

## Execution Flow

### For each unchecked task:

**Phase 1 — Implementation**

Read the plan preamble (Overview, Design References) and the current task's sub-bullets. Implement the task. Narrate what is being built, not the process itself.

> "Implementing token refresh endpoint"

**Phase 2 — Check chain**

Run the following checks in order. If any check fails, make adjustments and restart the chain from step 1. Track how many times the chain restarts at the same step (stall detection — see below).

1. **Build / tests / static checks**
   Run the project's build, test suite, and any static analysis (lint, type checks). All must pass.

2. **Coverage review**
   Assess whether key changes are covered by tests. Cover meaningful paths and edge cases; do not add tests for trivial details or things better left implicit (e.g. language-enforced invariants, pure delegation). Remove or skip tests that add no value.

3. **Design review**
   Compare the implementation against available design and architecture documentation. Check that the approach is consistent with stated goals, constraints, and architectural decisions. If no design docs are available, review against the plan preamble and existing code patterns.

4. **Consistency review**
   Review the changes against the rest of the codebase for:
   - **Naming conventions** — variables, functions, types, files follow established patterns
   - **Term usage** — avoid overloading existing terms with new meanings; use the vocabulary already established in the codebase
   - Any other consistency concerns identified by judgment (structure, error handling patterns, etc.)

If all four checks pass, proceed to Phase 3.

**Phase 3 — Complete task**

Mark the task as complete in `PLAN.md` (`- [x]`), then move to the next unchecked task.

## Stall Detection

Track check chain restarts **per task**, reset when a task completes.

If the chain restarts at the **same step 3 times** without reaching a later step, it is failing to make progress. Stop working and report:

```
Stuck on task [N]: [task title]
Check step: [step name]

Most recent check output:
[paste the actual output or assessment from the last attempt at this step]

Suggested next change:
[what would be attempted on the next pass]
```

Do not continue until the user responds. The counter resets when a new task begins.

## Narration Style

Describe what is being done, not the workflow machinery.

✅ "Implementing token expiry handling in auth middleware"
✅ "Adding unit tests for the refresh token path"
✅ "Adjusting error response format to match existing API conventions"

❌ "Beginning implementation phase for task 2"
❌ "Starting check chain pass 3, step 2: coverage review"
