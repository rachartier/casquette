---
name: casquette-skill-writing
description: >-
  Writes, revises or slims down an agent skill and its evals. Use when asked
  to create, edit, review or rename a skill.
---

# Skill writing

The user's instructions take precedence over this skill.

A skill earns its place only where it changes what the model would do without
it. When asked only to review or improve an existing skill, list numbered
findings with a reason each, and edit once told.

## 1. Pin down the job

Before writing, settle from the repo and conversation:

- The task, and the words users say when they want it.
- Neighbors: installed skills whose descriptions trigger on the same words.
  Decide which one wins which request.
- Gaps: what the model gets wrong without the skill. A real failure transcript
  is the best source. A skill written from imagined gaps fills up with rules
  the model already follows. If no transcript exists, ask for one before
  writing the body.
- The collection's conventions: name pattern, folder layout, where evals live,
  where skills are listed.

## 2. Write the evals

Write at least three in `evals/evals.json` before the body:

```json
[
  {
    "skills": ["<skill-id>"],
    "query": "What the user types.",
    "files": ["The starting project or input, in one sentence"],
    "expected_behavior": ["One observable action or output per line"]
  }
]
```

Cover the main path, a follow-up turn, and a restraint case where the right
result is no finding, change or question. A review's restraint case expects
no finding without a concrete failure, since a fixture rarely has no real
flaw. Write queries as a user would, with no hint of the answer. Each expected behavior must show in the transcript or
the files.

When a request asks for something a rule says to skip, expect the agent to do
what was asked and note the rule in one line. An expected behavior that demands
a refusal contradicts the query. Check each fixture against its query and
expectations before running it, since a fixture bug looks like a skill failure.
A planted flaw must be text the model will quote, not a request it may
refuse, such as one to write out its reasoning.
Name in `files` any stand-in for a tool the test machine lacks.

## 3. Write the frontmatter

- `name`: lowercase letters, digits and hyphens, up to 64 characters, equal to
  the folder name, following the collection's pattern.
- `description`: two or three lines in third person. Say what the skill does,
  then `Use when` with one trigger per distinct case. Leave out how it works.
  Add "not for X" only when a neighbor would otherwise win the wrong requests.
- Keep the skill model-invoked unless the user asks otherwise, and keep an
  existing skill's setting. A risky action gets a confirmation step in the body.

## 4. Write the body

Order it as the model runs it: numbered steps for a procedure, headed sections
for rules it looks up. End each step on a condition the model can check.

- **Gaps only.** Cut any sentence the model would follow untold, such as
  reading the diff before reviewing it, and any definition of a term, tool or
  format it already knows. Fix an observed failure with a rule as narrow as
  the failure.
- **One home per rule.** Cite another skill's rule by its ID instead of
  copying it. Point to a script, config file or `--help` that already says it.
- **Rules next to their use.** Explain a term or exception in the step that
  applies it.
- **General by default.** State the goal and the quality bar; a procedure
  the model knows takes one sentence, not numbered sub-steps. Give exact
  commands or a bundled script only for fragile, order-sensitive work.
- **Plain, positive instructions.** State the behavior wanted. Name a forbidden
  behavior only as a hard guardrail, beside its target. No "MUST" or
  "CRITICAL". Give the reason in a clause when it isn't obvious.
- **Literal effects.** "Only report high-severity issues" or "be conservative"
  makes a reviewer find less. Ask for every finding that meets an evidence bar,
  and let a severity column do the ranking.
- **End state, not self-checks.** Name the end state and the tool check that
  proves it (tests, a linter, a bundled script), and when to rerun it. Add no
  step that re-checks the model's own work (reread, re-diff, double-check,
  verify with a subagent): models already do it, and the extra pass costs
  tokens without improving the result.
- **Stops and permissions.** Open the body with "The user's instructions take
  precedence over this skill." Some models weigh skill text above the user
  otherwise. Say where the skill waits for the user; it grants no permission
  the user didn't give.
- **Sources over memory.** Say what to look up (the package index, `--help`,
  the manifest) rather than what to recall.
- **Reasoning stays private.** Ask for the result and a short reason. A
  request to write out the reasoning can be refused.
- **A worked example.** One concrete example of the output fixes its shape
  better than a description of it.
- **One word per concept.** Once a concept has a word ("finding", say), keep
  it across the file instead of switching to a synonym such as "issue".
- **Timeless.** No model names, dates or "new in" notes.

Move reference that only some runs need into a file beside SKILL.md, linked from SKILL.md with the condition for reading it. Link one level deep.
Add no README, changelog or empty folders.

For a bundled script: give its folder and exact command, say whether to run or
read it, have it fail with a message saying what to do, and comment each
constant's reason.

## 5. Prune

Review the finished skill and edit as you go:

- Delete any sentence that changes no behavior, any meaning said twice (here
  or in a skill it loads), and any step that re-checks the model's own work.
- Give each step and term the rule that governs it nearby.
- Remove any instruction that a literal reading would use to cut recall or add
  a pause the user doesn't want.
- Resolve conflicts between instructions, here or with a loaded skill. Models
  stop to ask when they meet one.
- Make every reference to another skill, script or file use its exact name.

## 6. Wire it in

- Add the skill to the collection's listing: README table, install notes for
  skills it loads.
- After a rename, grep the old ID across the repo, `AGENTS.md`, `CLAUDE.md`,
  other installed skills and skill symlinks, and update each. Leave matches
  that aren't the ID alone, such as `README.md` when renaming a `readme`
  skill. Ask before changing files outside the repo.
- Validate the evals JSON and run any bundled script once.

The skill is done when the evals exist, pruning finds nothing, and every
reference resolves. Suggest running the evals in fresh agents on each model and
effort level the user runs, given only the query and files, against no skill
or the previous version.
