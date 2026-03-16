# EphyraSoftware/skills

A collection of skills for [Claude Code](https://claude.ai/code).

Skills are automatically activated by Claude Code based on context — no manual invocation needed. Install them once and they're available across all your projects.

## Installation

Requires the [Claude Code](https://claude.ai/code) CLI (`claude`).

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/EphyraSoftware/skills/main/install.sh)
```

To pin to a specific version, replace `main` with a tag or commit SHA:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/EphyraSoftware/skills/v0.1.0/install.sh)
```

Running the command again will update an already-installed plugin to the latest version.

### What it does

1. Checks for conflicting skills — if another plugin has already installed a skill with the same name, it warns you and asks before continuing.
2. Registers this repository as a Claude Code marketplace (first install only).
3. Installs the `ephyra-skills` plugin at user scope, making all skills available globally.

To preview the steps without making any changes:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/EphyraSoftware/skills/main/install.sh) --dry-run
```

Restart any running Claude Code sessions after installing or updating.

## Skills

### [plan-execute](plugins/ephyra-skills/skills/plan-execute/README.md)

Structured, iterative execution of a coding plan from a `PLAN.md` file. Works through tasks one at a time with a check chain covering build/tests, coverage, design review, and codebase consistency. Includes stall detection that asks for help if the same check fails repeatedly.

Activates automatically when a `PLAN.md` is present in the working directory.
