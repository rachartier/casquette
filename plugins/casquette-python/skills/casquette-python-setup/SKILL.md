---
name: casquette-python-setup
description: >-
  Sets up a Python project's tooling (uv, ruff, ty, pytest, pre-commit) and,
  if the user wants one, a devcontainer. Use when the user starts a new Python
  project, or asks to update or reset an existing project's default config.
---

# Python project

The user's instructions take precedence over this skill.

The defaults are [templates/pyproject.toml](templates/pyproject.toml) (the
`[tool.*]` sections) and
[templates/pre-commit-config.yaml](templates/pre-commit-config.yaml) (the
hooks). To change a default, edit the template, not one project's copy.
`<skill>` is this file's folder. This skill installs and configures tools
only: it changes no source code and reports no lint, type or test findings.

## New project

1. `uv init --package <name>` (src layout, git repo). Raise
   `requires-python` to `>=3.12` if uv set it lower, or set the version the
   user names; ruff and ty read their target version from it.
2. `uv add --dev ruff ty pytest`.
3. Append `<skill>/templates/pyproject.toml` to `pyproject.toml`.
4. Copy `<skill>/templates/pre-commit-config.yaml` to
   `.pre-commit-config.yaml`, then `uvx pre-commit install`.
5. Ask whether the project needs a devcontainer. If yes and
   `command -v capsule` prints a path, set it up with the `casquette-capsule`
   skill. Otherwise write `.devcontainer/devcontainer.json`, with the image
   tag set to the `requires-python` minor version:

   ```json
   {
     "name": "<name>",
     "image": "mcr.microsoft.com/devcontainers/python:3.12",
     "remoteEnv": { "UV_LINK_MODE": "copy" },
     "postCreateCommand": "pip install uv && uv sync --locked"
   }
   ```

## Updating an existing project

1. Read the project's ruff, ty and pytest config (`pyproject.toml` or
   `ruff.toml`) and `.pre-commit-config.yaml`, and diff them against the
   templates.
2. Show the user each difference grouped as: missing defaults to add,
   project settings that differ from the defaults, and project-only
   settings. Add the missing defaults; change or remove anything else only
   for the items the user approves. Use this shape:

   ```text
   Missing defaults: [tool.ty] section (add)
   Differs: ruff select is E, F; the default also selects W, I, UP, B… (keep unless approved)
   Project only: [tool.mypy] section (keep unless approved)
   ```

3. Add any missing dev dependency with `uv add --dev`. Install hooks as in New
   project step 4 if the project had none. Hooks need a git repo, so if the
   project has none, ask the user before running `git init`.
4. Ask about a devcontainer as in New project step 5, unless the project
   already has `.devcontainer/`.
5. Ask the user whether to audit the existing code under the new config, and
   run the `casquette-python-audit` skill only if they say yes.

## Done

The setup is done when these all succeed:

```sh
uv run ruff check --show-settings >/dev/null   # ruff config parses
uv run ty --version && uv run pytest --version # dev tools installed
uvx pre-commit validate-config                 # hooks config is valid
test -x .git/hooks/pre-commit                  # hooks installed
```
