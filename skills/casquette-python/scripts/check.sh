#!/usr/bin/env bash
# Usage: check.sh <changed files>
# The project's ruff rules plus casquette-python's annotation, docstring,
# modernization, ignore-comment and size rules. The google docstring
# convention turns off D401, which casquette-python's summaries rely on.
set -euo pipefail

# Tests are scaffolding, not API: they skip the docstring and annotation rules.
exec uv run ruff check --output-format concise \
  --extend-select ANN,D,UP,PGH003,C90,PLR09 \
  --config 'lint.pydocstyle.convention = "google"' \
  --config 'lint.extend-per-file-ignores = {"tests/**" = ["D", "ANN"], "**/test_*.py" = ["D", "ANN"], "**/conftest.py" = ["D", "ANN"]}' \
  "$@"
