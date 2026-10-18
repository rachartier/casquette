# casquette

Agent skills for writing plain, simple Python, setting up its tooling,
running work in devcontainers, and writing READMEs and comments without
filler.

## Skills

| Skill | Use it to |
| --- | --- |
| `code-design` | Apply design rules to any code change: when an abstraction is justified, where new code goes, choosing a dependency, comments. |
| `python-code` | Write, edit or review Python: data and module structure, I/O wiring, typing, docstrings, vertical spacing, and a ruff check script. Builds on `code-design`. |
| `python-tooling` | Set up a new Python project (uv, ruff, ty, pytest, pre-commit) or bring an existing one's config up to these defaults. |
| `capsule` | Manage devcontainer templates and add a `.devcontainer/` to a project with the [capsule](https://github.com/rachartier/capsule) CLI. |
| `capsule-exec` | Run tests, builds and experiments inside a project's devcontainer with `capsule exec`. |
| `multi-stage-dockerfile` | Write multi-stage Dockerfiles for any language. |
| `readme` | Write or rewrite a README that is short, factual and code-first. |
| `remove-ai-slop` | Strip AI writing tells from prose, comments, docstrings and commit messages without changing their meaning. |

## Requirements

- [uv](https://docs.astral.sh/uv/) for `python-code` and `python-tooling`
- [capsule](https://github.com/rachartier/capsule), the
  [devcontainer CLI](https://github.com/devcontainers/cli) and Docker or
  Podman for `capsule` and `capsule-exec`

## Installation

Install every skill for your user with the
[skills](https://github.com/vercel-labs/skills) CLI (drop `-g` to install
into the current project):

```sh
npx skills add rachartier/casquette -g
```

List the skills, then install only some of them:

```sh
npx skills add rachartier/casquette --list
npx skills add rachartier/casquette -g --skill code-design --skill python-code
```

> [!IMPORTANT]
> `python-code` tells the agent to load `code-design` first. Install both.

Or clone the repo and link the skills into Claude Code:

```sh
git clone https://github.com/rachartier/casquette.git
for skill in casquette/skills/*/; do
    ln -s "$PWD/$skill" ~/.claude/skills/
done
```

## Usage

The agent picks a skill when the task matches its description. Ask for the
task:

```text
Start a new Python project called invoices.
```

`python-tooling` runs and creates the project with its tooling config.

Call a skill by name in Claude Code:

```text
/readme
```

## Python check

`python-code` verifies changed files with one ruff run: the project's own
rules plus annotation, docstring, pyupgrade and size rules, with concise
output. Run it from the project root:

```sh
~/.claude/skills/python-code/scripts/check.sh src/invoices/parser.py
```

`python-tooling` writes the same rules into the project from
[`skills/python-tooling/templates/pyproject.toml`](skills/python-tooling/templates/pyproject.toml),
with hooks from
[`skills/python-tooling/templates/pre-commit-config.yaml`](skills/python-tooling/templates/pre-commit-config.yaml).
