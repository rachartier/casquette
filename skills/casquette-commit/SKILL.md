---
name: casquette-commit
description: >-
  Commits work in Conventional Commits form, one commit per concern. Use when
  asked to commit, make commits, or split changes into commits.
---
# Casquette commit

Commit only what the user asked for. Don't amend, rebase, reset or push unless
the user asks.

## 1. Read the changes

Run `git status` and `git diff`, staged and unstaged. Group the changed files
by concern: a fix, a feature, a refactor, a doc change. A refactor that a
feature needs gets its own commit, placed before the feature.

If a file's concern is unclear, ask which commit it belongs to, and stage
nothing for it until the user answers.

## 2. Write each message

`type(scope): summary`: imperative, lowercase, no trailing period, 72
characters or fewer including the type. Use one of `feat`, `fix`, `refactor`,
`docs`, `test` or `chore`: `fix` for a bug fix, `feat` for new behavior,
`refactor` when behavior stays the same. Add a body only when it says what
changed and why, not how:

```text
refactor(orders): extract the retry loop from fetch_orders

The retry rule was mixed with HTTP parsing, so it could not be tested alone.
```

## 3. Stage and commit one concern at a time

Stage each file by name with `git add <path>...`. Never use `git add .` or
`git add -A`. Run `git diff --staged --stat` and check that it lists only this
commit's files, then commit. Repeat for the next concern.

When one file holds two concerns, stage only this concern's hunks:

1. `git diff -- <file> > <patch>`, with `<patch>` a temporary file outside the
   repo.
2. Delete every hunk that belongs to another concern from `<patch>`, keeping
   the file headers.
3. `git apply --cached <patch>`, then delete `<patch>`.
4. Check that `git diff --staged` shows only this concern before committing.

If the hunks can't be separated cleanly, ask the user which commit gets them.

## 4. Check

Run `git status`. The work is done when every change the user asked for is
committed, the files you asked about are still unstaged, and nothing else is
left staged. Each subject passes step 2. Report each commit's hash and subject.
