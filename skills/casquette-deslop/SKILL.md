---
name: casquette-deslop
description: >-
  Strips AI writing tells from text, comments, docstrings and commit
  messages. Use when asked to de-slop or humanize text or comments, to clean up
  AI-sounding wording, or to remove em dashes.
---
# Remove AI slop

The user's instructions take precedence over this skill.

Rewrite text so it reads like a knowledgeable person typing plainly, and
comments so they read like a senior engineer wrote them.

## Workflow

1. If the file is long (over ~400 lines), work section by section,
   since single-pass rewrites of long documents quietly compress the back
   half.
2. Apply the edits below.
3. Run the checks below on the result: a search catches the tells a reread
   misses.

## Checks

The checks use ripgrep (`rg`); without it, run `grep -nE` with the same
pattern and flags.

```bash
# Dashes used as punctuation (numeric ranges like 2019–2024 are fine)
rg -n '[—–]' <file>

# Spaced hyphens used as dashes, not list bullets (prose only; ' - ' in code is an operator)
rg -n '\S - ' <file>

# Banned vocabulary (in code, only matches in comments and messages count)
rg -n -i -w 'delve|tapestry|realm|landscape|testament to|navigate the complexities|at its core|ever-evolving|today.s fast-paced|leverage|utilize|robust|seamless|comprehensive|curated|elevate|unlock|supercharge|game-changer|cutting-edge|best-in-class|furthermore|moreover|additionally|that said|it.s worth noting|it.s important to note|crucial|vital|essential|powerful|key' <file>
```

In code, also run the project's linter and tests.

## Em dashes

The output contains no em dashes (—) and no en dashes (–) used as
punctuation. Replace each one with:

- a comma, when the aside is short and grammatically parallel
- a period and a new sentence, when the dash joins two independent clauses
- a colon, when what follows explains what precedes
- parentheses, when the aside is a true aside
- nothing, when the aside was filler

A spaced hyphen ( - ) is the same tic in disguise. Leave alone en dashes in
numeric ranges (2019–2024), hyphens in compound words (well-known), and any
dash inside code, inline code or a direct quotation.

**Examples:**

Input: The migration took three weeks — longer than we expected.
Output: The migration took three weeks, longer than we expected.

## Sentence shapes to remove

- **Not-X-but-Y reveals.** "It's not just a linter, it's a formatter." Say
  what it is. The contrast is almost always manufactured.
- **Colon-then-payoff.** "The result? Faster builds." Merge into one sentence.
- **Interrupting asides** that exist for rhythm rather than information.
- **Fragments used for punch.** "No fluff. Just results."
- **Rhetorical questions** as openers or transitions.
- **Rule-of-three padding.** Three-item lists where the third item is a
  synonym of the second. Cut to two, or find a real third.
- **Restatement and empty sentences.** A sentence that repeats the previous
  one or says nothing: delete it rather than rewrite it.

## Vocabulary

The word check above is the list of words to remove. Handle each match by
its kind:

- Register words and filler transitions (delve, furthermore…): cut them, or
  rewrite the sentence plainly. Keep "that said" when a real contrast
  follows.
- Product-marketing words: use the plain word or name the property.
  leverage → use, utilize → use, robust → (fast, well-tested, handles
  malformed input), comprehensive → complete or (cut), seamless → (cut, or
  say what doesn't break).
- Filler emphasis (crucial, vital, essential, powerful, key): cut it, or
  replace it with the reason the thing matters. "Key" counts only when it
  means important, never in "API key" or "key-value".

Also remove assistant chatter, which the check doesn't catch: openers and
sign-offs such as "Great question", "Certainly!", "Here's a…", "I hope this
helps", "Let me know if you have any questions".

## Code comments and docstrings

For comments, load `casquette-code-design` and apply its Comments rules.
Also remove or rewrite:

- **Assistant voice**: I, we, let's, here we, now we, `Note:`, "This ensures
  that", "This function is responsible for", "Simply".
- **Placeholders that hedge**: `# In a real implementation…`,
  `# For production, consider…`, `# You may want to…`. Delete them; if one
  marks a real gap, list it in the report.
- **Docstrings that restate the signature**: `get_user` documented as "Gets
  the user", or `Args: user_id (int): The user ID.` Keep only what a caller
  can't read from the name and types, and drop the docstring on a trivial
  private helper.
- **Emoji and exclamation marks** in comments and messages:
  `✅ Successfully saved report!` → `saved report to {path}`. Log and error
  text is behavior: change it only after checking that no test or alert
  matches on it, and list each change in the report.

Leave alone: tool directives (`# noqa`, `# type: ignore`, `# pragma`,
`# fmt: off`), license headers, shebangs, and `TODO`s with an owner or
ticket.

In commit messages, apply `casquette-commit`'s Message rules, and cut AI
attribution lines.

## Structure to fix

- Bold lead-ins on every bullet, when the bullets are short enough not to
  need them
- Headers on sections short enough to be a single paragraph
- An intro that announces what the document covers, followed by a conclusion
  that restates it. Cut both, or the weaker one.
- Takeaway lines appended to sections that already made their point
- Emoji in headers or bullets, unless the document clearly uses them on
  purpose

## Tone to fix

- Hedging stacks: "may potentially in some cases" → pick one hedge
- Unsourced authority: "studies show", "experts agree", "research
  suggests". Strip the borrowed credibility but keep the claim, so "studies
  show teams save 30% of their time" becomes "teams save 30% of their
  time", and flag it in the report so the author can source or cut it.
- Cheerleading about the subject matter
- Second-person coaching the author did not ask for: "You'll love how…"

## Preserve exactly

Only the wording moves. Keep unchanged:

- In code, everything except comments, docstrings and messages
- Code, inline code, YAML frontmatter, tables, link targets and anchor text
- Heading hierarchy and document order, apart from sections this skill says
  to cut
- Every technical claim, number, name, version and command
- Any voice or idiom that is clearly the author's own, including profanity,
  jokes and unusual sentence rhythm

Idiosyncrasy is not slop. When you can't tell whether something is the
author's voice or a model's tic, or can't rewrite a sentence without guessing
at facts, leave it and flag it: a slightly stilted true sentence beats a
smooth invented one. When the text already reads as the author's own voice,
make few or no edits and say so in the report.

## Output

Edit the file in place; for pasted text, return the revised text. Then give
a short report: the changes you were least sure about, and anything you left
alone because fixing it would have required knowing something you don't.
For published documentation, offer a unified diff.
