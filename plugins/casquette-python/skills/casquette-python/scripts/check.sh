#!/usr/bin/env bash
# Usage: check.sh <changed files>
# The project's ruff rules plus casquette-python's annotation, docstring,
# modernization, ignore-comment and size rules. The google docstring
# convention turns off D401, which casquette-python's summaries rely on.
set -euo pipefail

if command -v uv >/dev/null; then ruff=(uv run ruff)
elif [[ -x .venv/bin/ruff ]]; then ruff=(.venv/bin/ruff)
elif [[ -x .venv/Scripts/ruff.exe ]]; then ruff=(.venv/Scripts/ruff.exe)
elif command -v ruff >/dev/null; then ruff=(ruff)
elif command -v pipx >/dev/null; then ruff=(pipx run ruff)
else echo "No uv, .venv ruff, ruff or pipx found: install ruff into .venv with pip." >&2; exit 2
fi

# Tests are scaffolding, not API: they skip the docstring and annotation rules.
exec "${ruff[@]}" check --output-format concise \
  --extend-select ANN,D,UP,PGH003,C90,PLR09 \
  --config 'lint.pydocstyle.convention = "google"' \
  --config 'lint.extend-per-file-ignores = {"tests/**" = ["D", "ANN"], "**/test_*.py" = ["D", "ANN"], "**/conftest.py" = ["D", "ANN"]}' \
  "$@"
