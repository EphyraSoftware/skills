---
name: plan-execute
description: "Structured, iterative execution of a coding plan from a PLAN.md file. Implements tasks one at a time with a multi-step check chain and stall detection. ONLY use this skill when a PLAN.md file is present in the working directory. Do not activate without a PLAN.md. Triggers on: 'work through the plan', 'execute the plan', 'implement the plan', or any request to proceed with PLAN.md tasks."
---

# Plan Execute

Work through a `PLAN.md` file task by task, with a disciplined check chain after each implementation to catch issues before moving on.

See [references/plan-format.md](references/plan-format.md) for the `PLAN.md` format and task syntax.

## Prerequisites

**PLAN.md** must exist in the working directory. If absent, stop and tell the user.

**Build tooling** must be discoverable. Check `CLAUDE.md` / `AGENTS.md` first for build instructions. If absent, look for common build files (`Makefile`, `package.json`, `Cargo.toml`, `pyproject.toml`, `build.gradle`, etc.). If none are found, ask the user how to build and run tests before proceeding.

**Design documentation** must be locatable — either within the repository (e.g. `docs/`, `ARCHITECTURE.md`, `DESIGN.md`, ADR files) or referenced from a `CLAUDE.md` / `AGENTS.md` steering file. If none is found, note it and proceed using code-level inference for the design review step.

## Execution Flow

### For each unchecked task (in order):

**Phase 1 — Implementation**

Read the plan preamble (Overview, Design References) and the current task's sub-bullets before starting. Implement the task.

If the task cannot be implemented as written — missing dependency, ambiguous description, unavailable API — stop immediately and report what is blocking it. Do not retry; wait for user input to resolve the blocker before proceeding.

Narrate what is being built, not the process itself.

**Phase 2 — Check chain**

After implementation, run the following checks in order. When a check fails, make the targeted adjustments needed and re-run only the checks that are relevant to those adjustments (see *Targeted re-runs* below). Track how many times the chain fails at the same step without advancing (stall detection — see below).

1. **Build / unit tests / static checks**
   Discover and run the project's build, static analysis (lint, type checks), and unit tests for the affected module(s). All must pass.

2. **Coverage review**
   Assess whether key changes are covered by tests. Cover meaningful paths and edge cases — happy path, error/boundary conditions, any paths called out in the task's sub-bullets. Do not add tests for trivial details or things better left implicit (e.g. language-enforced invariants, pure delegation).

3. **Design review**
   Compare the implementation against available design and architecture documentation. Check that the approach is consistent with stated goals, constraints, and architectural decisions. If no design docs are available, review against the plan preamble and existing code patterns.

4. **Consistency review**
   Review the changes against the rest of the codebase for:
   - **Naming conventions** — variables, functions, types, files follow established patterns
   - **Term usage** — avoid overloading existing terms with new meanings
   - **Dead code** — remove any code made unreachable or obsolete by this change
   - Any other consistency concerns identified by judgment (structure, error handling patterns, etc.)

5. **Integration / regression check**
   Identify callers and consumers of any changed interfaces. Run integration tests if they exist. Verify that nothing outside the changed module is broken. This step runs last because integration tests are often slow — only run them once the earlier checks are clean.

**Targeted re-runs:** When adjustments are made after a failed check, only re-run the steps relevant to what changed:
- Code changed → re-run from step 1
- Tests added or changed → re-run from step 1
- Only comments, docs, or non-executable content changed → re-run from step 3
- Only naming / structure refactored (no logic change) → re-run from step 4

If all five checks pass, proceed to Phase 3.

**Phase 3 — Complete task**

Mark the task as complete in `PLAN.md` (`- [x]`), then move to the next unchecked task.

**Phase 4 — Plan complete**

When all tasks are checked off, report completion: summarise what was built across all tasks, and note any tasks that required stall intervention or user input to resolve.

Before finishing, defer to project guidelines (e.g. `CONTRIBUTING.md`, `CLAUDE.md`) for any required steps before submitting changes — such as changelog entries, version bumps, or documentation updates.

## Stall Detection

Track consecutive check chain failures at the **same step**, per task. Reset to zero when the chain advances past that step or when a task completes.

If the same step fails **3 consecutive times** without the chain advancing past it, it is failing to make progress. Stop working and report:

```
Stuck on task [N]: [task title]
Check step: [step name]

Most recent check output:
[paste the actual output or assessment from the last attempt at this step]

Suggested next change:
[what would be attempted on the next pass]
```

Do not continue until the user responds.

**After user input:**

By default, treat the user's response as guidance for breaking the loop — apply the changes they recommend, then re-run from the appropriate step per the *Targeted re-runs* rules above. The stall counter is **not** reset; it continues counting consecutive failures at the same step.

If the user explicitly directs a different workflow action — such as skipping a step, moving to the next task, or resetting the counter — follow their instruction. Only mark a task as complete if the user explicitly permits it.

The stall counter resets when a new task begins.

## Narration Style

Describe what is being done, not the workflow machinery.

✅ "Implementing token expiry handling in auth middleware"
✅ "Adding unit tests for the refresh token path"
✅ "Adjusting error response format to match existing API conventions"

❌ "Beginning implementation phase for task 2"
❌ "Starting check chain pass 3, step 2: coverage review"
