<p align="center">
<img width="248" height="248" alt="casquette-logo-no-text" src="https://github.com/user-attachments/assets/79e64257-4dc4-40b9-ba24-29f7634552cb" />
</p>

# Casquette

Agent skills for writing plain Python, running work in devcontainers, and
writing docs without filler.

## Skills

### Python

| Skill | Use it to |
| --- | --- |
| `casquette-code-design` | Apply design, scope and test rules to any code change, and run the checks that finish it. |
| `casquette-python` | Write, edit or review Python: structure, typing, docstrings, spacing. Builds on `casquette-code-design`. |
| `casquette-python-setup` | Set up a Python project with uv, ruff, ty, pytest and pre-commit, or update an existing one's config. |
| `casquette-python-audit` | Audit a Python project with its tools, then pick which findings to fix. |
| `casquette-review` | Review a change in any language against `casquette-code-design`, then pick which findings to fix. |

### Containers

| Skill | Use it to |
| --- | --- |
| `casquette-capsule` | Manage devcontainer templates and add a `.devcontainer/` to a project with [capsule](https://github.com/rachartier/capsule). |
| `casquette-capsule-exec` | Run tests, builds and experiments inside a project's devcontainer. |
| `casquette-dockerfile` | Write small, non-root, multi-stage Dockerfiles for any language. |

### Writing

| Skill | Use it to |
| --- | --- |
| `casquette-readme` | Write or rewrite a short, factual, code-first README. |
| `casquette-deslop` | Strip AI writing tells from prose, comments, docstrings and commit messages. |
| `casquette-skill-writing` | Write, revise or slim down an agent skill, with evals. |

## Requirements

- Python skills: [uv](https://docs.astral.sh/uv/).
  `casquette-python-audit` also needs bash, git and Python 3.11+.
- Container skills: [capsule](https://github.com/rachartier/capsule), the
  [devcontainer CLI](https://github.com/devcontainers/cli), and Docker or
  Podman.

## Installation

Install every skill for your user with the
[skills](https://github.com/vercel-labs/skills) CLI. Drop `-g` to install
into the current project.

```sh
npx skills add rachartier/casquette -g
```

Or pick some of them:

```sh
npx skills add rachartier/casquette --list
npx skills add rachartier/casquette -g --skill casquette-code-design --skill casquette-python
```

> [!IMPORTANT]
> Some skills call others. Install them together:
>
> - `casquette-python` needs `casquette-code-design`
> - `casquette-python-audit` uses `casquette-python` and `casquette-python-setup`
> - `casquette-review` uses `casquette-code-design` and the language's skill (`casquette-python`)
> - `casquette-deslop` uses `casquette-code-design` for code comments
> - `casquette-capsule-exec` uses `casquette-capsule` to install capsule

Without the CLI, clone the repo and link the skills into your agent's skills
folder:

```sh
skills_dir=~/.agents/skills  # your agent's skills folder
git clone https://github.com/rachartier/casquette.git
mkdir -p "$skills_dir"
for skill in casquette/skills/*/; do
    ln -s "$PWD/$skill" "$skills_dir/"
done
```

## Usage

Ask for the task. The agent picks the skill whose description matches:

```text
Start a new Python project called invoices.
Review my uncommitted changes.
```

Or name the skill:

```text
Use the casquette-readme skill to rewrite README.md.
```

# Python Tooling defaults
`casquette-python-setup` writes its ruff, ty and pytest defaults from
[`templates/pyproject.toml`](skills/casquette-python-setup/templates/pyproject.toml)
and its hooks from
[`templates/pre-commit-config.yaml`](skills/casquette-python-setup/templates/pre-commit-config.yaml).
