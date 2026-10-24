---
name: casquette-python-audit
description: >-
  Audits and grades a Python project with its quality tools (lint, types,
  complexity, dead code, security, tests) and a read of the riskiest code.
  Use when asked to audit or grade a Python project.
---

# Python audit

The user's instructions take precedence over this skill.

`<skill>` below is the absolute path of the folder holding this SKILL.md. Run
commands from the project root.

## 1. Run the tools

```bash
bash <skill>/scripts/audit.sh                  # whole project (default)
bash <skill>/scripts/audit.sh --changed        # uncommitted changes only
bash <skill>/scripts/audit.sh --base main      # changes since a branch
bash <skill>/scripts/audit.sh lint types tests # only these tools
```

Tool names: lint, format, types, complexity, deadcode, duplicates, security,
tests. Each tool runs with the project's own configuration, and its output
appears under a `###` heading, capped at 40 lines with the cut reported.
That output is the evidence for the audit; rerun a tool alone only to see
lines the cap cut.

## 2. Read the riskiest code

Start with the files the tool output points to (failing tests, errors,
complexity rank C or worse), then entry points and code that handles input,
files, subprocesses or persistence. Look for what the tools can't see, such
as failures reported as success and data that can be lost. Stop when each of
those files has been read once.

## 3. Present the findings

Merge the tool output and your reading into one table, sorted by severity
and numbered from 1. A problem two tools report (an undefined name from ruff
F821 and ty) is one finding.

| Severity | Meaning |
|---|---|
| CRITICAL | Broken now or exploitable: failing test, undefined name, crash on normal use, data loss, `shell=True` on a string a caller passes in |
| HIGH | A bug on plausible input: swallowed error, wrong type passed, mutable default, tests that don't run |
| MEDIUM | Costs maintainers: a unit doing several things, duplication, dead code, a module with low coverage |
| LOW | Style: missing docstrings or annotations, `Any` without a reason, naming, imports, formatting, commented-out code |
| INFO | Worth knowing, nothing to fix: a tool that couldn't run, a long but cohesive unit (dispatch table, linear procedure), a design note |

Size findings (C901, PLR09xx, radon) are signals: rank one MEDIUM only when
the unit does more than one thing, otherwise INFO.

When the project has its own ruff config, the lint section's header says
`project config + audit baseline`: ruff added the bug rules `F`, `E9`, `B`,
`PLE`, `PLW` and `BLE` on top. Mark the Source of a finding whose rule the
project doesn't select as `(audit baseline)`, for example
`ruff B006 (audit baseline)`. Then compare the project's selected rules with
`<skill>/assets/ruff.toml` and add one INFO finding naming the missing rule
families, with the fix "update the config with the
`casquette-python-setup` skill".

The report is three parts, in this order:

1. Scores: the mean as the header, then 0-10 for correctness, tests, typing,
   style, complexity, design, security, each with a reason of a few words.
2. The finding count per severity.
3. The findings, with LOW findings grouped by rule:

```
**Score: 6.4/10**

| Area | Score | Why |
|---|---|---|
| Correctness | `████░░░░░░`  4 | `reslt` undefined in runner.py |
| Tests | `███████░░░`  7 | 41 passed, 2 failed, 78% coverage |
| Security | `██████████` 10 | nothing found |

**16 findings**: 1 critical, 2 high, 4 medium, 9 low

| # | Severity | Where | Problem | Fix | Source |
|---|---|---|---|---|---|
| 1 | CRITICAL | src/app/runner.py:7 | `reslt` is undefined, so run() always raises NameError | Rename to `result` | ruff F821, ty |
| 2 | HIGH | src/app/runner.py:5 | Mutable default `env={}` is shared between calls | Default to None | ruff B006 |
| 3 | LOW | 2 files | 3 public functions have no docstring | Add Google-style docstrings | ruff D103 |
```

Then ask which findings to fix, recommending the CRITICAL and HIGH ones (up to
MEDIUM when there are none), with your question tool if you have one. The
user can also type a list such as `1, 3, 7-9`. Change no code until the
answer.

## 4. Fix and recheck

Fix every chosen finding, most severe first, without stopping to check in
between. Write the fixes as the `casquette-python` skill says, in the project's
style, with a test for each bug fixed. Then rerun only the tools the
fixes touched, by name. The work is done when no chosen finding shows in the
rerun and no new CRITICAL or HIGH finding appeared. Report in a few lines
what was fixed, and what wasn't and why.
