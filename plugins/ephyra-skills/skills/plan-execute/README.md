# plan-execute

A skill for working through a `PLAN.md` coding plan task by task, with a structured check chain to catch issues before moving on.

Each task goes through two phases: implementation, then a check chain covering build/tests, test coverage, design review, and codebase consistency. If a check fails, adjustments are made and the chain restarts. Built-in stall detection asks for user input if the same check fails three times in a row on the same task.

See `SKILL.md` for the full workflow and `PLAN.md` format.
