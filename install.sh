#!/usr/bin/env bash
# install.sh — Install or update EphyraSoftware/skills as a Claude Code plugin
#
# Usage:
#   ./install.sh           # Install or update
#   ./install.sh --dry-run # Show what would happen without making changes
#
# Requirements: claude CLI must be installed and authenticated.

set -euo pipefail

PLUGIN_NAME="ephyra-skills"
MARKETPLACE_NAME="ephyra-skills"
REPO="EphyraSoftware/skills"
REPO_URL="https://github.com/${REPO}.git"
DRY_RUN=false
TEMP_DIR=""

# ── Argument parsing ───────────────────────────────────────────────────────────
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --help|-h)
      echo "Usage: $0 [--dry-run]"
      echo ""
      echo "Installs or updates the $REPO skills plugin for Claude Code."
      echo "Skills are installed globally (user scope) and available in all projects."
      echo ""
      echo "Options:"
      echo "  --dry-run   Show what would happen without making changes"
      exit 0
      ;;
    *) echo "Unknown option: $arg"; exit 1 ;;
  esac
done

# ── Helpers ────────────────────────────────────────────────────────────────────
info()    { echo "  $*"; }
ok()      { echo "✓ $*"; }
warn()    { echo "⚠ $*"; }
err()     { echo "✗ $*" >&2; }
run()     { if $DRY_RUN; then echo "  [dry-run] $*"; else "$@"; fi; }

echo ""
echo "EphyraSoftware/skills — Claude Code plugin installer"
echo "====================================================="
$DRY_RUN && echo "(dry-run mode — no changes will be made)"
echo ""

# ── Check prerequisites ────────────────────────────────────────────────────────
if ! command -v claude &>/dev/null; then
  err "claude CLI not found. Install Claude Code first: https://claude.ai/download"
  exit 1
fi

if ! command -v git &>/dev/null; then
  err "git not found. Please install git and try again."
  exit 1
fi

# ── Locate skills directory ────────────────────────────────────────────────────
# When run via `bash <(curl ...)`, BASH_SOURCE[0] is /dev/fd/N — not a real path.
# In that case, clone the repo to a temp directory instead.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$SCRIPT_DIR/plugins/ephyra-skills/skills"

if [[ ! -d "$SKILLS_DIR" ]]; then
  info "Script run via pipe — cloning repository to a temporary directory..."
  TEMP_DIR="$(mktemp -d)"
  trap 'rm -rf "$TEMP_DIR"' EXIT
  git clone --depth 1 "$REPO_URL" "$TEMP_DIR" --quiet
  SKILLS_DIR="$TEMP_DIR/plugins/ephyra-skills/skills"
fi

if [[ ! -d "$SKILLS_DIR" ]]; then
  err "skills/ directory not found at $SKILLS_DIR"
  exit 1
fi

# Find all skill names this plugin provides
mapfile -t OUR_SKILLS < <(find "$SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)

info "Skills provided by this plugin:"
for skill in "${OUR_SKILLS[@]}"; do
  info "  • $skill"
done
echo ""

# Look for any existing skill directories with the same names that are NOT
# managed by this plugin. We check the user-scope plugin install location.
PLUGIN_SKILLS_ROOT="${HOME}/.claude/plugins"
CONFLICTS=()

for skill in "${OUR_SKILLS[@]}"; do
  # Search for SKILL.md files matching this skill name, excluding our own plugin
  while IFS= read -r found; do
    # Normalise: get the parent plugin dir
    plugin_dir=$(echo "$found" | sed "s|${PLUGIN_SKILLS_ROOT}/||" | cut -d/ -f1-3)
    # If it's from our own plugin, skip
    if [[ "$found" == *"/${PLUGIN_NAME}/"* ]]; then
      continue
    fi
    CONFLICTS+=("$skill (found at: $found)")
  done < <(find "$PLUGIN_SKILLS_ROOT" -path "*/skills/${skill}/SKILL.md" 2>/dev/null)
done

# Also check ~/.claude/commands for any command with the same name as a skill
for skill in "${OUR_SKILLS[@]}"; do
  if [[ -f "${HOME}/.claude/commands/${skill}.md" ]]; then
    CONFLICTS+=("$skill (found as user command: ~/.claude/commands/${skill}.md)")
  fi
done

if [[ ${#CONFLICTS[@]} -gt 0 ]]; then
  warn "Conflicting skills found that are NOT managed by this plugin:"
  for c in "${CONFLICTS[@]}"; do
    warn "  • $c"
  done
  echo ""
  warn "Proceeding would not overwrite these — Claude Code loads skills by name"
  warn "and duplicates may cause unexpected behaviour. Resolve conflicts first."
  echo ""
  read -r -p "Continue anyway? [y/N] " confirm
  [[ "${confirm,,}" == "y" ]] || { info "Aborted."; exit 0; }
  echo ""
fi

# ── Check if marketplace is already registered ─────────────────────────────────
MARKETPLACE_REGISTERED=false
if claude plugin marketplace list 2>/dev/null | grep -q "$MARKETPLACE_NAME"; then
  MARKETPLACE_REGISTERED=true
fi

# ── Check if plugin is already installed ──────────────────────────────────────
PLUGIN_INSTALLED=false
if claude plugin list 2>/dev/null | grep -q "$PLUGIN_NAME"; then
  PLUGIN_INSTALLED=true
fi

# ── Install / update ───────────────────────────────────────────────────────────
if $PLUGIN_INSTALLED; then
  info "Plugin '$PLUGIN_NAME' is already installed — updating..."
  run claude plugin update "$PLUGIN_NAME"
  ok "Plugin updated."
else
  # Register marketplace if not already present
  if ! $MARKETPLACE_REGISTERED; then
    info "Registering marketplace from $REPO..."
    run claude plugin marketplace add "$REPO" --scope user
    ok "Marketplace registered."
  else
    ok "Marketplace already registered."
    info "Refreshing marketplace..."
    run claude plugin marketplace update "$MARKETPLACE_NAME"
  fi

  info "Installing plugin '$PLUGIN_NAME' (user scope — available in all projects)..."
  run claude plugin install "${PLUGIN_NAME}@${MARKETPLACE_NAME}" --scope user
  ok "Plugin installed."
fi

echo ""
echo "Done. Skills are now available globally in Claude Code."
echo "Restart any running Claude Code sessions for changes to take effect."
echo ""
echo "Installed skills:"
for skill in "${OUR_SKILLS[@]}"; do
  echo "  • $skill"
done
echo ""
