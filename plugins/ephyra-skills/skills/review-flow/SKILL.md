---
name: review-flow
description: "Pull request creation and review response workflow. Three sequential phases: (1) create a PR with conventional commits, (2) address reviewer feedback with fixup commits, (3) prepare for merge by autosquashing and rebasing. Triggers on: 'create a pull request', 'create a PR', 'open a PR', 'address review', 'address feedback', 'address comments', 'respond to review', 'ready to merge', 'prepare to merge'."
---

# Review Flow

A three-phase workflow for pull request lifecycle: creating PRs with conventional commits, responding to reviewer feedback with fixup commits and comment replies, and preparing the branch for merge.

## Phase 1 — Create Pull Request

Triggered when the user asks to create a PR for completed work.

### Steps

1. **Choose a branch name**
   Select a branch name that reflects the work done — matching the issue, feature, or fix. Use kebab-case (e.g. `feat/add-token-refresh`, `fix/config-parse-error`). If already on a suitable branch, keep it.

2. **Stage and commit**
   Review all changes and identify those relevant to the current feature, fix, or change. Do not assume everything that has changed needs to be committed — only stage what belongs to this change. Organise relevant changes into one or more conventional commits (`feat:`, `fix:`, `refactor:`, `docs:`, `test:`, `chore:`, etc.). Each commit should be a coherent, self-contained unit. Write short commit messages; include *why* only when the change is complex enough to warrant it.

3. **Push and open the pull request**
   Push the branch to the remote. Open a pull request using whatever tooling is available for the code hosting platform. The title should be short (under 70 characters). The body should summarise the changes with bullet points:

   ```
   ## Summary
   - <bullet points>
   ```

4. **Present the PR URL to the user.**

## Phase 2 — Address Review

Triggered when the user asks to address review feedback on an existing PR.

### Prerequisites

There must be an open PR on the current branch. If not, ask the user which PR to address.

### Steps

1. **Pull the working branch**
   Pull the latest changes for the working branch before starting — the user may have rebased or amended outside the conversation.

2. **Fetch review comments**
   Retrieve all review comments on the PR using whatever tooling is available for the code hosting platform. On first pass, consider all comments. On subsequent passes, read all comments for context but only process new comments and new replies in existing threads since the last review pass.

3. **Evaluate comments**
   Consider all actionable comments together before making changes. For each comment or thread, classify it:

   - **Valid** — the reviewer's point is correct and should be addressed.
   - **Partially valid** — the reviewer identified a real issue but the suggested fix is not ideal. A different change better serves the intent of the change.
   - **Invalid** — the comment is based on a misunderstanding, is stylistic preference that conflicts with project conventions, or would compromise the coherence of the change.

   Do not blindly apply every suggestion. The goal is to keep the code change coherent with the original intent — the bug being fixed, the issue being addressed, or the feature being implemented. The planned set of changes for valid and partially valid comments must also be coherent with each other, not just individually correct. Consider the existing code, the changed code, and the intent of the change when deciding what to modify.

   When a comment identifies a problem — whether it is about style, naming, unnecessary comments, dependency usage, or any other pattern — check the entire change for other occurrences of the same mistake. A single comment about one instance is a prompt to fix all instances. Do not wait for the reviewer to flag each occurrence individually.

4. **Make changes with fixup commits**
   For valid and partially valid comments, make the necessary code changes. Commit them as fixup commits targeting the original conventional commit that introduced the code being modified:

   ```
   git commit --fixup=<original-commit-hash>
   ```

   Each fixup commit should reference the commit it fixes, so the changes logically belong to the right original commit.

5. **Push**
   Push the updated branch.

6. **Respond to comments**
   For every comment from the current review round, post a reply:

   - **Valid, addressed as requested** — briefly describe what was changed.
   - **Partially valid, different change made** — explain why a different approach was chosen and what was done instead.
   - **Invalid, no change made** — provide a technically accurate justification for why the comment was not actioned.

   Be specific and direct. Accuracy matters more than tone.

### Subsequent review rounds

If the user returns with another round of review, only act on new comments and new replies in existing threads since the last pass. Use all comment content as context, but do not re-process threads that have already been resolved unless the reviewer explicitly requests further changes. Follow the same pull → evaluate → change → push → respond flow.

## Phase 3 — Prepare for Merge

Triggered when the reviewer indicates the change is ready to merge.

### Steps

1. **Pull the working branch**
   Pull the latest changes for the working branch.

2. **Autosquash fixup commits**
   Rebase with `--autosquash` to fold fixup commits into their target commits:

   ```
   git rebase --autosquash <base-branch>
   ```

   This combines the fixup commits with the original conventional commits they were targeting.

3. **Rebase against the base branch**
   If the autosquash rebase also rebases against the latest base branch, this is already done. Otherwise, rebase the branch onto the latest version of the base branch.

   If there are conflicts during the rebase against the base branch, abandon the rebase, squash only the fixup commits instead, and inform the user that they need to resolve conflicts with the base branch manually.

4. **Push**
   Force-push the rebased branch with `--force-with-lease` (this is expected after a rebase).
