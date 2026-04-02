# review-flow

A skill for pull request lifecycle management. Covers three sequential phases:

1. **Create PR** — choose a branch name matching the work, commit relevant changes using conventional commits, push, and open a pull request with a summary.

2. **Address review** — fetch PR review comments, evaluate each for validity against the original intent of the change, make changes as fixup commits against the original commits, push, and reply to every comment explaining what was changed or why feedback was declined. Subsequent review rounds only process new or updated comment threads.

3. **Prepare for merge** — autosquash fixup commits into their target conventional commits, rebase against the base branch, and push. If there are conflicts with the base branch, squash fixups only and leave conflict resolution to the user.

See `SKILL.md` for the full workflow.
