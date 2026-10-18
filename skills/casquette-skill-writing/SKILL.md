---
name: casquette-skill-writing
description: >-
  Writes, revises or slims down an agent skill and its evals. Use when asked
  to create, edit, review or rename a skill.
---

# Skill writing

A skill is extra instructions for a model that is already capable. It earns
its place only where it changes what the model would do without it, so each
line either fixes a gap or goes.

When the user asks only for improvements to an existing skill, run step 5 on
it, list the findings numbered with a reason each, and stop; edit once told.

## 1. Pin down the job

Settle these before writing, asking the user only what the repo and the
conversation can't answer:

- The task the skill handles and the words users say when they want it.
- Neighbors: the installed skills whose descriptions trigger on the same
  words. Decide which one wins for which request.
- The gaps: what the model gets wrong or does inconsistently on this task
  without the skill. A transcript of a real failure is the best source. A
  skill written from imagined gaps fills up with instructions the model
  already follows.
- Conventions of the collection it joins: name pattern, folder layout, where
  evals live, where skills are listed.

## 2. Write the evals

Write at least three in `evals/evals.json` before the body, in this shape:

```json
[
  {
    "skills": ["<skill-id>", "<any skill it loads>"],
    "query": "What the user types.",
    "files": ["The project or input the run starts from, described in one sentence"],
    "expected_behavior": [
      "One observable action or output per line"
    ]
  }
]
```

Cover the main path, a follow-up turn (such as "fix 1 and 3"), and a
restraint case: input where the right result is no finding, no change or no
question. Write each query as a real user would, with no hint of the
expected answer. Each expected behavior is an action or result a judge can
see in the transcript or the files, not a wording to match.

## 3. Write the frontmatter

- `name`: lowercase letters, digits and hyphens, at most 64 characters, the
  same as the folder name, following the collection's pattern.
- `description`: what the skill does, then `Use when` and the triggers, in
  third person. It is loaded in every conversation and is the only thing the
  model sees when choosing a skill, so:
  - Lead with the verb and object that name the job.
  - Give one trigger per distinct case; synonyms for one case are one
    trigger.
  - Leave out how the skill works; the body says that.
  - Keep it to two or three lines. A broad trigger loads the skill on
    unrelated work.
  - Add an exclusion ("not for X") only when a neighbor would otherwise
    win the wrong requests.
- Invocation: keep the skill model-invoked unless the user asks for an
  explicit-only one (`disable-model-invocation: true`), and keep an existing
  skill's setting. A risky action calls for a confirmation step in the body,
  not a hidden skill.

## 4. Write the body

Order it as the model runs it: numbered steps for a procedure, headed
sections for rules it looks up. Each step ends on a condition the model can
check ("each of those files has been read once", "the checks pass and no
chosen finding remains").

- **Gaps only.** Delete any sentence the model would follow without being
  told, such as reading the diff before reviewing it or tracing data flow.
  Fix an observed failure with a rule as narrow as the failure; one example
  or preference doesn't become a universal requirement.
- **One home per rule.** When another skill owns a rule, load that skill by
  its ID and cite the rule; a copy drifts from the original. When a script,
  config file or `--help` already says something, point to it.
- **Rules next to their use.** Explain a term or exception in the step that
  applies it.
- **Freedom to match the risk.** Give exact commands or a bundled script for
  fragile, order-sensitive work (setup, migrations, tool runs). Give goals and
  a quality bar for judgment work (review, writing), where a fixed recipe
  gets in the way.
- **Plain, positive instructions.** State the behavior you want ("write
  one-line comments"); name a forbidden behavior only as a hard guardrail,
  next to the target. Use normal case and no "MUST" or "CRITICAL": capable
  models follow instructions literally and overreact to emphasis. Give the
  reason in a clause when it isn't obvious; the model applies a reason to
  cases the rule doesn't name.
- **Literal effects.** "Only report high-severity issues" or "be
  conservative" makes a reviewer find less. Ask for every finding that meets
  an evidence bar, and let a grouping or severity column do the ranking.
- **Named checks.** Name the check that proves the work done (the tests
  that cover the change, the type checker, running the command once) and
  when to rerun it. Some models skip checks at low effort and others
  over-test, so a named check beats both silence and "always run
  everything".
- **Stops and permissions.** Say where the skill waits for the user ("change
  no code until the answer") and that the user's instructions win over the
  skill. Everything else, it does without asking. The skill grants no
  permission the user didn't give: an action outside the task, or one that
  writes to an outside system, still needs the user.
- **Facts from the source.** Say what to look up instead of recalling
  (licenses on the package index, flags in `--help`, versions in the
  manifest). Leave out "minimize tool calls"; it makes models answer from
  memory.
- **Reasoning stays private.** Ask for the result and a short reason for
  it. "Think step by step" adds nothing on models that already reason, and
  asking to write the reasoning out in the reply can be refused.
- **A worked example.** One concrete example of the output fixes its shape
  and level of detail better than a description of it.
- **One word per concept.** Pick "finding", "check" or "change" and keep it
  across the file.
- **Timeless.** No model names, dates or "new in" notes.

Keep SKILL.md as short as the task allows; a line limit is a ceiling, not
a target. Move reference that only some runs need into a file next to it,
linked from SKILL.md with the condition for reading it ("for a Dockerfile
template, read `templates.md`"). Link only from SKILL.md, one level deep.
Add only files the work uses: no README, changelog or empty folders inside
the skill.

### Bundled scripts

- Write `<skill>` for the skill's folder and give the exact command line.
- Say whether to run a script or read it.
- The script handles its own errors with a message that says what to do,
  and comments every constant with its reason.
- List what it needs (interpreter, tools) once, in the README or the
  section that runs it.

## 5. Prune

Read the finished skill once per question:

1. Does each sentence change behavior against what the model does without
   it? Delete those that don't, whole.
2. Is any meaning said twice, in this skill or in a skill it loads?
3. Does any step or term appear without the rule that governs it nearby?
4. Could any instruction be read literally in a way that cuts recall or
   adds a pause the user doesn't want?
5. Do any two instructions conflict, here or with a skill it loads? Models
   stop to ask when they meet a conflict.
6. Does every reference to another skill, script or file use its exact,
   current name?

## 6. Wire it in

- Add the skill where the collection lists its skills (README table, install
  notes for skills it loads).
- After a rename, grep every old ID across the repo, the user's agent
  instruction files (`AGENTS.md`, `CLAUDE.md`), other installed skills and
  skill symlinks, and update each.
- Validate the evals JSON and run any bundled script once.

The skill is done when the evals exist, step 5 finds nothing, and every
reference resolves. Suggest running the evals in fresh agents on each model
and effort level the user runs, against no skill for a new one or the
previous version for a revision, giving each run only the query and its
files.
