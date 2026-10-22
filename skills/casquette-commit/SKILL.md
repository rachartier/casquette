---
name: casquette-commit
description: >-
  Commits work in Conventional Commits form, one logical change per commit. Use
  when asked to commit, make commits, or split changes into commits.
---
# Casquette commit

The user's instructions override this skill. Commit only what was asked; don't
amend, rebase, reset or push unless asked.

## Split

Read `git status` and the staged and unstaged diff. Make one commit per logical
change, with its tests and docs. Give these their own commit: a
behavior-preserving refactor a feature needs (placed before it), and moves,
renames or reformatting. Otherwise, one commit.

Run the project's test or build command once per commit (say so in the report
if there is none). If a split would make a commit fail it, keep those changes
together.

If a file's purpose is unclear, or its hunks can't be cleanly separated, ask
which commit gets it and leave it unstaged until the user answers.

## Message

`type(scope): summary`, with type one of `feat`, `fix`, `refactor`, `docs`,
`test`, `chore`, chosen by the main effect. Lowercase, imperative, no period,
72 characters max in total. If the subject needs "and", split the commit.

Breaking change: add `!` to the type of its main effect (removing a public
function is `feat!`, not `refactor!`) and a footer
`BREAKING CHANGE: <what breaks and what to do instead>`.

Default to no body. Add one, wrapped at 72, only if it tells a reader of the
subject and diff something they can't see there: why the change was needed, or
a side effect. Never write a body that restates the subject, lists the changed
files or functions, describes what the diff shows, or claims generic benefits
("improves readability", "for maintainability"). If every sentence fails this
test, omit the body.

```text
refactor(orders): extract the retry loop from fetch_orders

The retry rule was mixed with HTTP parsing, so it could not be tested alone.
```

No body needed:

```text
docs(readme): fix typo in invoice sentence
```

## Stage

Stage by path with `git add <path>...`, never `git add .` or `git add -A`.

To commit only some hunks of a file: `git diff --output=<tmp> -- <file>` with
`<tmp>` outside the repo, delete the other changes' hunks from `<tmp>`, then
`git apply --cached <tmp>` and delete `<tmp>`.

When done, only the files you asked about are unstaged and nothing else is
staged. Report each commit's hash and subject.
