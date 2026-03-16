# EphyraSoftware/skills

A collection of skills for [Claude Code](https://claude.ai/code) and [OpenClaw](https://openclaw.ai).

Skills are automatically activated based on context — no manual invocation needed. Install them once and they're available across all your projects.

## Requirements

Both install scripts require:

- **bash** 4.0 or later
- **git** — used to clone and update the repository

The Claude Code script additionally requires:

- **[Claude Code CLI](https://claude.ai/code)** (`claude`) — installed and authenticated

## Installation

### Claude Code

Skills are installed globally and available in all projects.

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/EphyraSoftware/skills/main/install.sh)
```

To pin to a specific version, replace `main` with a tag or commit SHA:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/EphyraSoftware/skills/v0.2.0/install.sh)
```

Running the command again will update an already-installed plugin to the latest version.

#### What it does

1. Checks for conflicting skills — if another plugin has already installed a skill with the same name, it warns you and asks before continuing.
2. Registers this repository as a Claude Code marketplace (first install only).
3. Installs the `ephyra-skills` plugin at user scope, making all skills available globally.

To preview the steps without making any changes:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/EphyraSoftware/skills/main/install.sh) --dry-run
```

### OpenClaw

Skills are symlinked into `~/.openclaw/workspace/skills/` from a stable local clone at `~/.local/share/ephyra-skills`.

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/EphyraSoftware/skills/main/install-openclaw.sh)
```

Running the command again will pull the latest changes and update existing symlinks.

#### What it does

1. Clones the repository to `~/.local/share/ephyra-skills` (or pulls if already cloned).
2. Checks for conflicting skill directories in `~/.openclaw/workspace/skills/` not managed by this script — warns and skips them rather than overwriting.
3. Creates symlinks for each skill. Updates existing managed symlinks in place.

To preview the steps without making any changes:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/EphyraSoftware/skills/main/install-openclaw.sh) --dry-run
```

Restart any running Claude Code or OpenClaw sessions after installing or updating.

## Skills

### [plan-execute](plugins/ephyra-skills/skills/plan-execute/README.md)

Structured, iterative execution of a coding plan from a `PLAN.md` file. Works through tasks one at a time with a check chain covering build/tests, coverage, design review, consistency, and integration checks. Includes stall detection that asks for help if the same check fails repeatedly.

Activates automatically when a `PLAN.md` is present in the working directory.
