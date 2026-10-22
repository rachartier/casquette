---
name: casquette-code-design
description: >-
  Sets the rules for code changes in any language: scope, when an abstraction
  is justified, where new code goes, tests, choosing a dependency, comments,
  and the checks that finish a change. Use when writing, editing, testing or
  reviewing code.
---
# Code design

These rules apply to code you write or change. When reviewing, apply them to
the diff, not to the code around it.

## Principles

Choose the simplest solution that fully solves the problem: the one a new
teammate understands in one read. When rules conflict, the order is:
correctness and the explicit requirement, fail fast, separation of concerns,
KISS/YAGNI, DRY. If a requirement forces a violation, do what was asked and
flag it in one sentence.

- **KISS / YAGNI**: before adding an abstraction, name the second concrete
  use that needs it today. If there is none, don't add it.
- **Reuse before writing**: reach, in this order, for code the project
  already has, the standard library, a dependency already installed, then a
  new library that passes Dependencies below. Write it yourself only when
  none fits, or when the library would weigh more than the few clear lines it
  replaces.
- **Separation of Concerns**: keep I/O, business logic, orchestration and
  presentation apart, so business logic is testable without the network,
  filesystem or UI. Separate them as functions first. Give a concern its own
  module when no module owns it yet, or when the owning file passes ~300 lines
  or another module needs it. A small tool or script is one module and one
  test module.
- **DRY**: tolerate small, incidental repetition rather than a premature
  abstraction.
- **Fail Fast**: validate at the boundary (user input, external systems) and
  raise a specific error immediately. Don't swallow exceptions, return
  silent defaults or add fallbacks that hide failures. Don't handle cases
  that can't happen inside your own code. An external system fails in more
  ways than an error status: a timeout, a malformed body, an out-of-range
  value. Handle them all where the request says that failure is handled.

## Over-engineering

Simple means easy to read and change, not few files or few lines. A module
that owns one responsibility is fine. These are not:

- an interface or base class with a single implementation (a fake that an
  existing test passes in counts as a second one)
- a factory, registry, manager, builder or strategy for a single case (see
  KISS / YAGNI)
- a wrapper that only forwards a call, or indirection a reader must jump
  through to find what happens
- a class where a function would do
- a helper extracted only so a test can reach it or inject into it; extract
  one when a second caller or a clearer name needs it, and test through the
  public function
- configuration, options or hooks nobody asked for
- a design pattern chosen by name rather than by a need in front of you

## Designing a change

Before adding behavior (anything beyond a local fix):

1. Use the project's AGENTS.md map if it has one.
2. Name what the change decides, what it talks to (database, network,
   files, UI) and what it coordinates, and list every place it must reach:
   callers, tests, fixtures, templates, exports. Update each of them and
   nothing else.
3. Put each in the module that already owns it. New code with no owner
   starts in one new module named after the problem it solves.
4. Make the change easy, then make the easy change: if the code is hard to
   change (it would take on a second responsibility, a name misleads, the
   piece you need is buried in a larger function), first refactor just that
   code without changing behavior: this preparatory refactoring is part of
   the task.
5. On a change that spans several modules, name the next request the
   change makes likely. Where two designs cost the same today, pick the one
   that makes that request easy (where a responsibility lives, how data is
   shaped or stored). Build none of it, and name it in one line at the end.

Don't impose an architecture (layered, hexagonal, clean architecture)
unless the project already uses one or the user asks.

## Scope of a change

- Every changed line traces to the request. Add no feature, file, doc,
  comment, docstring, annotation or refactor outside the touched code; name
  such extras at the end instead.
- Read what the change touches and what depends on it, not the whole repo.
- Report an unrelated problem (a bug, a broken test) in one line instead of
  fixing it.
- Solve the general problem. Don't hard-code a value or add a special case
  that only makes a test pass. If a test looks wrong, or the task can't be
  done as asked, say so.

## Dependencies

Prefer an existing library over writing your own when it:

- solves the actual problem without a pile of glue code
- is maintained: a release or real commits in the last ~12 months, supports
  the project's language version, issues get answers
- is established: widely used, documented, with type information where the
  language has it
- has a permissive license (MIT, BSD, Apache-2.0, ISC, PSF, MPL-2.0). If a
  better fit has another license, name it and its license to the user and
  let them choose. Never use a package with no license.

Check license and activity on the package index or the repository, not from
memory. Prefer a library already in the dependency tree over a new one that
does the same.

## Reporting a change

After a code change, add a line to the report only when it applies: a new
dependency (name, reason, license), a parameter added only so a test can
verify the change, or a size signal (long function, many parameters) you kept,
with why.

## Tests

- Add a test only when the change needs one to be verified, and make it check
  behavior, not mirror the implementation. Cover the boundaries, ties and error
  paths the request implies.
- Never weaken a check to pass it: no deleting, skipping or loosening a test,
  and no suppression or config change that only hides a finding.
- Change an existing test only when the requested behavior changes it, and say
  which test and why.

## Done

A change is done when the linter, type checker and relevant tests pass, or
you've said which one couldn't run and why, and the temporary files you
created are deleted. Run the checks once after the edits; after a fix, rerun
the checks the fix touches. Don't check after every edit unless the task
asks for a check loop.

## Comments

Keep comments sparse and useful: when code is full of comments, readers and
reviewers skim past all of them and miss the few that matter. Comment only
what the code can't say for itself, in one short line of plain words. Say
why, never what, and never how you got here. Keep comments true when the
code changes. No section comments that designate areas.

```python
# Good: API returns naive datetimes; treat as UTC (#412).
# Bad:  loop over users / changed this to fix the bug
```
