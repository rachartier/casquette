---
name: python-review
description: >-
  Audits a Python project with its linters, type checker, complexity,
  dead-code, security and test tools plus a read of the riskiest code, then
  lists findings by severity for the user to pick what to fix. Use when asked
  to review, audit or grade the quality of a Python project or its recent
  changes.
---

# Python review

`<skill>` below is the absolute path of the folder holding this SKILL.md. Run
commands from the project root. When the user names a scope or a tool, that
wins over the defaults here.

## 1. Run the tools

```bash
bash <skill>/scripts/review.sh                  # whole project (default)
bash <skill>/scripts/review.sh --changed        # uncommitted changes only
bash <skill>/scripts/review.sh --base main      # changes since a branch
```

The script runs ruff, the format check, the type checker (ty, or the
project's mypy or pyright), radon, vulture, pylint duplicate-code, bandit and
pytest with coverage, each with the project's own configuration. A project
with no ruff configuration gets `<skill>/assets/ruff.toml`, the same rules
`python-tooling` sets up. A project with one keeps its own style rules, and
ruff adds a review baseline of bug rules on top (`F`, `E9`, `B`, `PLE`,
`PLW`, `BLE`), minus the project's ignores. Each tool's output appears under
a `###` heading, capped at 40 lines with the cut reported. That output is the
evidence for the review; rerun a tool alone only to see lines the cap cut.

## 2. Read the riskiest code

Start with the files the tool output points to (failing tests, errors,
complexity rank C or worse), then entry points and code that handles input,
files, subprocesses or persistence. Look for what the tools can't see: logic
errors, swallowed errors, failures reported as success, data that can be
lost, behavior without a test, unclear names, a unit doing several things,
abstraction no caller needs. Stop when each of those files has been read
once.

## 3. Present the findings

Merge the tool output and your reading into one table, sorted by severity
and numbered from 1. A problem two tools report (ruff S602 and bandit B602)
is one row.

| Severity | Meaning |
|---|---|
| CRITICAL | Broken now or exploitable: failing test, undefined name, crash on normal use, data loss, `shell=True` with outside input |
| HIGH | A bug on plausible input: swallowed error, wrong type passed, mutable default, tests that don't run |
| MEDIUM | Costs maintainers: a unit doing several things (complexity rank C or worse is the usual pointer), duplication, dead code, a module with low coverage |
| LOW | Style: missing docstrings or annotations, `Any` without a reason, naming, imports, formatting, commented-out code |
| INFO | Worth knowing, nothing to fix: a tool that couldn't run, a long but cohesive unit (dispatch table, linear procedure), a design note |

Size findings (C901, PLR09xx, radon) are signals: rank one MEDIUM only when
the unit does more than one thing.

When lint ran with the review baseline, mark the Source of a finding whose
rule the project doesn't select as `(review baseline)`, for example
`ruff B006 (review baseline)`. Then compare the project's selected rules with
`<skill>/assets/ruff.toml` and add one INFO row naming the missing rule
families, with the fix "update the config with the `python-tooling` skill".

The report is three parts, in this order:

1. One line with the test result and coverage.
2. A 0-10 grade with a few words of reason for each of: correctness, tests,
   typing, style, complexity, design, security.
3. The table, with LOW rows grouped by rule:

```
| # | Severity | Where | Problem | Fix | Source |
|---|---|---|---|---|---|
| 1 | CRITICAL | src/app/runner.py:7 | `reslt` is undefined, so run() always raises NameError | Rename to `result` | ruff F821, ty |
| 2 | HIGH | src/app/runner.py:5 | Mutable default `env={}` is shared between calls | Default to None | ruff B006 |
| 3 | LOW | 2 files | 3 public functions have no docstring | Add Google-style docstrings | ruff D103 |
```

Then ask which rows to fix as one single-choice question, with your
multiple-choice question tool if you have one, otherwise in plain text:

- "Critical and high (Recommended)", with their numbers. If there are none,
  recommend "Up to medium" instead.
- "Up to medium", with numbers.
- "Everything except info", with numbers.
- "Nothing for now".

The user can also type a list such as `1, 3, 7-9`. The code stays untouched
until the answer.

## 4. Fix and recheck

Fix every chosen row, most severe first, without stopping to check in
between. Write the fixes as the `python-code` skill says, in the project's
style, with a test for each bug fixed. Use the tools' own fixers where they
apply (`ruff check --fix`, `ruff format`). Then rerun the tools the fixes
touched:

```bash
bash <skill>/scripts/review.sh lint types tests
```

Tool names: lint, format, types, complexity, deadcode, duplicates, security,
tests. The work is done when no chosen row shows in the rerun and no new
CRITICAL or HIGH finding appeared. Report in a few lines what was fixed, and
what wasn't and why.
