#!/usr/bin/env bash
# install-openclaw.sh — Install or update EphyraSoftware/skills for OpenClaw
#
# Usage:
#   bash <(curl -fsSL https://raw.githubusercontent.com/EphyraSoftware/skills/main/install-openclaw.sh)
#   ./install-openclaw.sh           # Install or update
#   ./install-openclaw.sh --dry-run # Show what would happen without making changes
#
# Requirements: git, bash 4+
# The repo is cloned to ~/.local/share/ephyra-skills and skills are symlinked
# into ~/.openclaw/workspace/skills/.

set -euo pipefail

REPO_URL="https://github.com/EphyraSoftware/skills.git"
CLONE_DIR="${HOME}/.local/share/ephyra-skills"
OPENCLAW_SKILLS_DIR="${HOME}/.openclaw/workspace/skills"
SKILLS_SUBPATH="plugins/ephyra-skills/skills"
DRY_RUN=false

# ── Argument parsing ───────────────────────────────────────────────────────────
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --help|-h)
      echo "Usage: $0 [--dry-run]"
      echo ""
      echo "Installs or updates EphyraSoftware/skills for OpenClaw."
      echo "Skills are symlinked into ~/.openclaw/workspace/skills/."
      echo ""
      echo "Options:"
      echo "  --dry-run   Show what would happen without making changes"
      exit 0
      ;;
    *) echo "Unknown option: $arg"; exit 1 ;;
  esac
done

# ── Helpers ────────────────────────────────────────────────────────────────────
info()  { echo "  $*"; }
ok()    { echo "✓ $*"; }
warn()  { echo "⚠ $*"; }
err()   { echo "✗ $*" >&2; }
run()   { if $DRY_RUN; then echo "  [dry-run] $*"; else "$@"; fi; }

echo ""
echo "EphyraSoftware/skills — OpenClaw installer"
echo "==========================================="
$DRY_RUN && echo "(dry-run mode — no changes will be made)"
echo ""

# ── Check prerequisites ────────────────────────────────────────────────────────
if ! command -v git &>/dev/null; then
  err "git not found. Please install git and try again."
  exit 1
fi

if [[ ! -d "$OPENCLAW_SKILLS_DIR" ]]; then
  err "OpenClaw skills directory not found at $OPENCLAW_SKILLS_DIR"
  err "Is OpenClaw installed and configured?"
  exit 1
fi

# ── Clone or update the repo ───────────────────────────────────────────────────
if [[ -d "$CLONE_DIR/.git" ]]; then
  info "Updating local copy at $CLONE_DIR..."
  run git -C "$CLONE_DIR" pull --ff-only --quiet
  ok "Repository updated."
else
  info "Cloning repository to $CLONE_DIR..."
  run git clone --depth 1 "$REPO_URL" "$CLONE_DIR" --quiet
  ok "Repository cloned."
fi

SKILLS_SOURCE="${CLONE_DIR}/${SKILLS_SUBPATH}"

if [[ ! -d "$SKILLS_SOURCE" ]]; then
  err "Skills directory not found at $SKILLS_SOURCE"
  exit 1
fi

# ── Discover skills ────────────────────────────────────────────────────────────
mapfile -t SKILLS < <(find "$SKILLS_SOURCE" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)

info "Skills to install:"
for skill in "${SKILLS[@]}"; do
  info "  • $skill"
done
echo ""

# ── Conflict detection ─────────────────────────────────────────────────────────
CONFLICTS=()
for skill in "${SKILLS[@]}"; do
  target="${OPENCLAW_SKILLS_DIR}/${skill}"
  if [[ -L "$target" ]]; then
    link_dest="$(readlink "$target")"
    # Managed by us if it points into our clone dir
    if [[ "$link_dest" != "${CLONE_DIR}"* ]] && [[ "$link_dest" != "${SKILLS_SOURCE}"* ]]; then
      CONFLICTS+=("$skill (symlink pointing elsewhere: $link_dest)")
    fi
  elif [[ -d "$target" ]]; then
    CONFLICTS+=("$skill (plain directory — not managed by this script)")
  fi
done

if [[ ${#CONFLICTS[@]} -gt 0 ]]; then
  warn "Conflicting skills found that are NOT managed by this script:"
  for c in "${CONFLICTS[@]}"; do
    warn "  • $c"
  done
  echo ""
  warn "These will be skipped. Remove or relocate them manually to install."
  echo ""
fi

# ── Install / update symlinks ──────────────────────────────────────────────────
INSTALLED=()
UPDATED=()
SKIPPED=()

for skill in "${SKILLS[@]}"; do
  source_path="${SKILLS_SOURCE}/${skill}"
  target="${OPENCLAW_SKILLS_DIR}/${skill}"

  # Skip conflicts
  if [[ -d "$target" && ! -L "$target" ]]; then
    SKIPPED+=("$skill")
    continue
  fi
  if [[ -L "$target" ]]; then
    link_dest="$(readlink "$target")"
    if [[ "$link_dest" != "${CLONE_DIR}"* ]] && [[ "$link_dest" != "${SKILLS_SOURCE}"* ]]; then
      SKIPPED+=("$skill")
      continue
    fi
    # Managed symlink — update it (re-link in case clone path changed)
    run ln -sfn "$source_path" "$target"
    UPDATED+=("$skill")
  else
    # Fresh install
    run ln -s "$source_path" "$target"
    INSTALLED+=("$skill")
  fi
done

echo ""
[[ ${#INSTALLED[@]} -gt 0 ]] && { ok "Installed:"; for s in "${INSTALLED[@]}"; do info "  • $s"; done; }
[[ ${#UPDATED[@]} -gt 0 ]]   && { ok "Updated:";   for s in "${UPDATED[@]}";   do info "  • $s"; done; }
[[ ${#SKIPPED[@]} -gt 0 ]]   && { warn "Skipped (conflict):"; for s in "${SKIPPED[@]}"; do info "  • $s"; done; }

echo ""
echo "Done. Skills are now available in OpenClaw."
echo "Restart any running OpenClaw sessions for changes to take effect."
echo ""
