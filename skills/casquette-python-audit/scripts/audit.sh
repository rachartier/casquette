#!/usr/bin/env bash
# Runs Python quality tools on the project in the current directory and prints
# each tool's own concise output.
#
# A tool uses the project's configuration when the project has one, and the
# defaults in this skill's assets/ folder (or the tool's own) otherwise. Ruff
# also adds the bug rules in BASELINE_RULES to a project's own config. Tools
# come from the project's .venv first, then the PATH, then uvx.
#
# Usage: audit.sh [--changed | --base REF] [TOOL...]
#   TOOL is any of: lint format types complexity deadcode duplicates security tests
#   --changed / --base REF limit lint, format, types, complexity and security
#   to the Python files changed (uncommitted, or since REF).
#   MAX_LINES (default 40) caps each tool's output; the cut is reported.
set -uo pipefail

SKILL="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MAX_LINES="${MAX_LINES:-40}"
ALL_TOOLS=(lint format types complexity deadcode duplicates security tests)
# Tests and build output are skipped by the code checks; pytest covers the tests.
EXCLUDED="tests,test,.venv,venv,build,dist"
# Bug rules every project gets, since they catch crashes whatever its style config.
BASELINE_RULES="F,E9,B,PLE,PLW,BLE"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export PYTHONDONTWRITEBYTECODE=1 COVERAGE_FILE="$TMP/.coverage"

targets=()
tools=()
scoped=0
while (($#)); do
  case "$1" in
    --changed) scoped=1; mapfile -t targets < <({ git diff --name-only HEAD; git ls-files --others --exclude-standard; } | grep '\.py$' | sort -u) ;;
    --base)
      # A bad ref would empty the file list and report a clean audit.
      if (($# < 2)) || ! git rev-parse --verify --quiet "$2^{commit}" >/dev/null; then
        echo "--base needs a branch or commit that exists, for example: --base main" >&2
        exit 2
      fi
      scoped=1; mapfile -t targets < <({ git diff --name-only "$2...HEAD"; git diff --name-only HEAD; git ls-files --others --exclude-standard; } | grep '\.py$' | sort -u); shift ;;
    *) tools+=("$1") ;;
  esac
  shift
done
((${#tools[@]})) || tools=("${ALL_TOOLS[@]}")
if ((!scoped)); then
  if [[ -d src ]]; then targets=(src); else targets=(.); fi
fi
# Changed files that were deleted can't be checked.
existing=()
for target in "${targets[@]}"; do [[ -e "$target" ]] && existing+=("$target"); done
targets=("${existing[@]}")
if ((${#targets[@]} == 0)); then
  echo "No Python file to audit in this scope."
  exit 0
fi

has_config() {  # tool_name file...
  local name="$1"
  shift
  grep -qs "^\[tool\.${name}[].]" pyproject.toml && return 0
  local file
  for file in "$@"; do [[ -f "$file" ]] && return 0; done
  return 1
}

tool() {  # name -> the command to run it
  if [[ -x ".venv/bin/$1" ]]; then echo ".venv/bin/$1"
  elif command -v "$1" >/dev/null; then echo "$1"
  else echo "uvx $1"
  fi
}

run_tool() {  # title tool_name args...
  local title="$1" cmd
  read -ra cmd <<<"$(tool "$2")"
  shift 2
  run "$title" "${cmd[@]}" "$@"
}

run() {  # title command...
  local title="$1"
  shift
  echo "### $title"
  echo "\$ $*"
  "$@" >"$TMP/out" 2>&1
  local code=$?
  local lines
  lines=$(wc -l <"$TMP/out")
  head -n "$MAX_LINES" "$TMP/out"
  ((lines > MAX_LINES)) && echo "... $((lines - MAX_LINES)) more lines (rerun this tool alone, or raise MAX_LINES)"
  echo "(exit $code)"
  echo
}

project_ruff_ignores() {  # -> the project's ruff ignore list, comma-separated
  python3 - <<'EOF'
import tomllib
from pathlib import Path

for name, prefix in (("ruff.toml", ()), (".ruff.toml", ()), ("pyproject.toml", ("tool", "ruff"))):
    path = Path(name)
    if not path.is_file():
        continue

    config = tomllib.loads(path.read_text())
    for key in prefix:
        config = config.get(key, {})

    if config:
        lint = config.get("lint", {})
        codes = [
            code
            for table in (config, lint)
            for key in ("ignore", "extend-ignore")
            for code in table.get(key, [])
        ]
        print(",".join(codes))
        break
EOF
}

lint() {
  # A project config decides style, but the bug rules always run on top of it.
  # Rules selected on the command line override the config's ignores, so those
  # are passed again.
  local ignores config source="project config + audit baseline"
  ignores="$(project_ruff_ignores)"
  config=(--extend-select "$BASELINE_RULES" --extend-ignore "B008${ignores:+,$ignores}")
  if ! has_config ruff ruff.toml .ruff.toml; then
    config=(--config "$SKILL/assets/ruff.toml")
    source="skill defaults"
  fi
  run_tool "lint: ruff ($source)" ruff check --no-cache --output-format concise "${config[@]}" "${targets[@]}"
}

format() {
  if has_config black; then
    run_tool "format: black" black --check --quiet "${targets[@]}"
  else
    run_tool "format: ruff" ruff format --check --no-cache "${targets[@]}"
  fi
}

types() {
  if has_config mypy mypy.ini .mypy.ini && ! has_config ty ty.toml; then
    run_tool "types: mypy (project config)" mypy --no-error-summary --no-pretty "${targets[@]}"
  elif has_config pyright pyrightconfig.json && ! has_config ty ty.toml; then
    run_tool "types: pyright (project config)" pyright "${targets[@]}"
  else
    run_tool "types: ty" ty check --output-format concise "${targets[@]}"
  fi
}

complexity() {
  # Only functions ranked C or worse (complexity above 10) and files with a low
  # maintainability index; everything else is fine and would only cost tokens.
  run_tool "complexity: radon cc (rank C and worse)" radon cc --min C --show-complexity --average --ignore "$EXCLUDED" "${targets[@]}"
  run_tool "maintainability: radon mi (rank C)" radon mi --min C --show --ignore "$EXCLUDED" "${targets[@]}"
}

deadcode() {
  # Dead code only makes sense across the whole project.
  if has_config vulture; then
    run_tool "dead code: vulture (project config)" vulture
  else
    run_tool "dead code: vulture" vulture --min-confidence 80 --exclude "$EXCLUDED" .
  fi
}

duplicates() {
  run_tool "duplicates: pylint" pylint --recursive=y --disable=all --enable=duplicate-code \
    --ignore="$EXCLUDED" --score=n --reports=n .
}

security() {
  local config=()
  has_config bandit && config=(-c pyproject.toml)
  run_tool "security: bandit" bandit -q -r "${config[@]}" -x "./tests,./test,./.venv" \
    -f custom --msg-template "{relpath}:{line}: {severity}/{confidence} {test_id} {msg}" "${targets[@]}"
}

tests() {
  local runner
  if [[ -f uv.lock ]] || has_config uv; then
    runner=(uv run --with pytest-cov pytest)
  elif [[ -f poetry.lock ]] && command -v poetry >/dev/null; then
    runner=(poetry run pytest)
  elif [[ -x .venv/bin/python ]] && .venv/bin/python -c "import pytest_cov" 2>/dev/null; then
    runner=(.venv/bin/python -m pytest)
  else
    # A throwaway environment with the project installed; creates no .venv.
    runner=(uv run --no-project --with-editable . --with pytest --with pytest-cov pytest)
  fi
  run "tests: pytest with coverage" "${runner[@]}" -q -p no:cacheprovider --tb=line \
    --cov=. --cov-report=term-missing:skip-covered
}

for name in "${tools[@]}"; do
  case "$name" in
    lint | format | types | complexity | deadcode | duplicates | security | tests) "$name" ;;
    *) echo "Unknown tool '$name'. Choose from: ${ALL_TOOLS[*]}" >&2; exit 2 ;;
  esac
done
