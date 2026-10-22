---
name: casquette-review
description: >-
  Reviews a code change for bugs, risks, missing tests and design-rule
  breaks. Use when asked to review a diff, commit, branch or PR. Not for
  checking a change against an issue or spec.
---

# Casquette review

Review the change as the developer who gets paged when it breaks.

## 1. Read the change

- Scope and focus: what the user names (uncommitted or staged work, a
  commit, a PR, files, a ref for everything since that ref, or a
  concern such as security). Nothing named: the changes since the
  merge-base with the default branch (`git merge-base HEAD main`, or `master`
  when the repo has no `main`). When there is no such branch, use the
  uncommitted changes, or the last commit when there are none. On the default
  branch the merge-base is `HEAD`, so this means the uncommitted changes.
- Load `casquette-code-design`, and the language's skill when one exists
  (`casquette-python` for Python). Their rules are the standard for this
  review, applied to the changed lines.
- Read the diff and the code it reaches. When a signature, return value or
  behavior changes, grep every caller, including files the diff doesn't
  touch.
- Find the expected load in the repo (README, deploy config): one person
  running a script, or many users and processes at once.
- Run the project's checks in check-only mode: the linter on the changed
  files (for Python, `casquette-python`'s `scripts/check.sh`), the type
  checker, and the tests that cover the change. Keep findings on changed
  lines or on callers the change breaks.

## 2. Look for

Report every finding that passes step 3, whatever its size; the groups in
step 4 do the ranking. In order of importance:

1. **Bug:** a wrong result, a crash, a missed edge case (empty, zero, last
   item, rounding, time zones), a caller the change breaks, a fix made in one
   caller while the shared function stays wrong.
2. **Risk:** injection, secrets, weak randomness, unchecked outside input,
   swallowed errors, writes in the wrong order or outside a transaction,
   data that can be lost.
3. **Scale and speed:** fine for one user, wrong or slow for many at the
   expected load: check-then-write races, the same work in every process,
   state that only grows, a query per item, quadratic work on large input.
4. **Missing test:** risky new logic (a branch, a parser, money, security, a
   data write, a bug fix) with no test that fails when it breaks.
5. **Design:** a break of a rule in `casquette-code-design` or the language
   skill; cite the rule.

## 3. Check each finding

- A bug, risk or scale finding names a concrete case: this input or
  situation gives this wrong result. A design finding names the rule and
  the line.
- Re-read the lines and confirm: the caller exists, the value can really be
  empty, the code really is unused.
- A shortcut whose comment names its limit is a decision, unless the
  expected load already crosses that limit.
- The fix is the smallest one that works; prefer one that deletes code.

Drop each finding that fails these checks, and any matter of taste no rule
backs.

## 4. Report

Write in plain English: short sentences, everyday words, and a technical
term explained the first time it appears. The reader may never have seen
this code.

Start with `What this change does:` in two or three sentences, then
`Assumed load:` in one line.

Then the findings in three groups by what skipping them costs, skipping
empty groups, numbered across groups so the user can say "fix 2 and 5":

- **Must fix:** skipping it gives wrong results, loses data or leaves a
  security hole.
- **Should fix:** skipping it costs someone later: a slowdown, a missing
  test, code that is hard to change.
- **Nice to have:** optional.

Each finding has four parts of one or two short sentences:

```markdown
2. **An outage looks like a quiet day** (`sync/client.py:31-44`)
   - **What this is:** `fetch_orders` downloads new orders from the shop API.
   - **Problem:** After the last failed retry it returns an empty list, so
     when the API is down the sync reports "0 new orders" and exits 0.
   - **Fix:** Raise after the last retry and delete the `return []` branch
     (casquette-code-design: Fail Fast).
   - **If we skip it:** Orders go missing until someone notices by hand.
```

End with:

- `Verdict: Ship.` or `Verdict: fix 1 and 3 first.` Use `Verdict: Ship.` when
  only nice-to-have findings remain.
- `Outside the diff:` one line per problem on lines the change neither touches
  nor breaks, when there is one.
- `Not checked:` in one line, when something mattered and couldn't be
  checked.

With no findings, write `What this change does:`, `Assumed load:`, then
`Looks good. Ship.` and one line on what you checked, and stop there.

Otherwise ask which numbers to fix, recommending the Must fix ones, with
your question tool if you have one. Change no code until the answer, unless
the user already named the findings to fix.

## 5. Fix and recheck

Fix every chosen finding, most severe first, as `casquette-code-design` and the
language skill say, with a test that fails without the fix for each bug fixed.
Change only code in the diff, or a caller the diff breaks. Then rerun the
checks from step 1 that the fixes touch. The work is done when they pass and
no chosen finding remains. Report in a few lines what was fixed, and what
wasn't and why.
