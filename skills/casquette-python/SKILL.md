---
name: casquette-python
description: >-
  Sets the Python rules: uv, the ruff and ty check, data and module structure,
  I/O wiring, typing, docstrings and vertical spacing. Use when writing, editing
  or reviewing Python code.
---
# Python style

The user's instructions take precedence over this skill.

Apply the `casquette-code-design` skill first; this skill adds only what is
specific to Python. Like it, these rules apply to code you write or change.
Where both are silent, follow the Google Python Style Guide.

## Tooling

Use uv unless the project uses another tool or you're told otherwise:
`uv add` for dependencies, `uv add --dev` for tooling.

After the last edit, run these as the final step, in this order. The rerun
rule is in `casquette-code-design`'s Done section.

1. If `pyproject.toml` or the dev dependencies name a formatter, run it on the
   changed files.
2. Run `<skill>/scripts/check.sh <changed files>`, where `<skill>` is the folder
   holding this SKILL.md: one ruff run with the project's rules plus this
   skill's annotation, docstring, modernization, ignore-comment and size rules.
   The script runs ruff through uv; in a project that uses another tool, run
   the same `ruff check` options through that tool (the script lists them).
3. Run the type checker that `pyproject.toml` configures (`[tool.ty]`,
   `[tool.mypy]` or `[tool.pyright]`); when it configures none, run
   `uvx ty check --output-format concise`.
4. Run the tests for the changed modules, for example
   `uv run pytest tests/test_orders.py`; run `uv run pytest` alone when unsure
   which tests those are.

Fix every finding on a line you wrote or changed, except a kept size signal
(see Size signals). Leave findings on lines you didn't touch.

To create a project or update its default config, use the
`casquette-python-setup` skill. Otherwise leave a project's ruff config as it
is.

## Structure

- Data is a `@dataclass(frozen=True)`, or the project's model library.
- Name modules after their responsibility, never `utils.py`, `helpers.py`,
  `common.py`, `manager.py` or `misc.py`.
- A class may subclass a Protocol or ABC directly, but not a class that already
  subclasses one.

### I/O and wiring

Put logic worth testing in functions, or methods on data classes, that take
data and return data, and do the I/O around them (in `main` or the caller).
Test them directly; that needs no injection. The I/O code still gets a test:
parse responses in a pure function, and test the rest (requests, error
handling, exit codes) through the one seam. A function asked to work on a
file is still two: one that takes the rows, and a thin one that reads the
file and calls it.

Inject only when a test can't avoid the I/O otherwise, for example when the
logic and the I/O interleave (retries, polling, paging). Then add one seam per
I/O dependency, at the outermost function that needs it, and none below it:

- a single function: a keyword-only `Callable` parameter whose default is the
  real one;
- an object whose several methods you call (a client, a repository): a
  `Protocol` in the consuming module, with only those methods, passed through
  `__init__`.

No seam that no test uses, no DI framework, service locator or global
singleton. Tests pass small fakes instead of `mock.patch`-ing module paths.

In existing code, keep public signatures and constructors and test in the
project's current style (patching a stdlib seam such as `time.sleep` is
fine). Add a parameter to an existing signature only if it is the only way
to verify the change.

### Size signals

The check reports size findings (C901, PLR09xx). Also take a second look
at a function over ~40 lines or a class over ~150 lines or with many public
methods. These are signals, not limits.

When one is crossed, check whether the unit still does one thing. If it
does (a cohesive public API, a dispatch table, a long but linear
procedure), keep it: leave the finding as it is, without `# noqa`, and name
it in one line in your final reply. If it doesn't, and your change pushes it
over, split it as preparatory refactoring; if the split isn't possible, name
the finding in one line instead.

## Types

Use the newest syntax the project's `requires-python` allows (3.12 when it
sets none): write aliases with a `type` statement, not Google's `TypeAlias`,
where the version allows it.

- Before `Any`, try a type parameter, `object` or a `Protocol`. A kept `Any`
  gets `# noqa: ANN401 - <reason>`; the reason keeps it from being a
  suppression that only hides a finding (`casquette-code-design`, Tests).
- Decorators preserve signatures with `ParamSpec`:
  `def deco[**P, R](f: Callable[P, R]) -> Callable[P, R]`.
- Silence ty with its rule-specific comment, `# ty: ignore[rule]`. A bare
  `# ty: ignore` hides every error on its line.
- `if TYPE_CHECKING:` only for a name used only in annotations. Fix an import
  cycle caused by typing in the design, not with `Any`.

## Docstrings

Google style (3.8), always `"""`. Which functions get one is set by
`casquette-code-design` (Scope of a change); among those, the check enforces
public ones, and a non-obvious private one gets one too.

- Write for a caller who sees only the signature: semantics and side
  effects (e.g. mutates an argument), not implementation.
- Summary in descriptive style ("Fetches rows…", not "Fetch…" or "This
  function…"). No types in `Args:`; the annotations have them. `Raises:`
  lists only exceptions callers should handle, not checks that reject API
  misuse (see `casquette-code-design`, Fail Fast).
- A class summary says what an instance represents ("The address of a
  cheese shop."); a `@property` is a noun phrase ("The table path.").

```python
def fetch_rows(table: Table, keys: Sequence[str]) -> Mapping[str, Row]:
    """Fetches rows from a table.

    Args:
        table: An open table handle.
        keys: Keys of the rows to fetch. Missing keys are skipped.

    Returns:
        A mapping from each found key to its row.

    Raises:
        ConnectionError: The table is unreachable.
    """
```

## Vertical spacing

Function bodies are paragraphs: one blank line between steps (guards,
inputs, computation, side effects, result). The formatter never adds these
lines, so write them yourself, even when the surrounding code is dense.

- A step's lines stay together, and a call stays next to the check of its
  result.
- The body starts right after the `def` line or docstring, with no blank line
  between a block's header and its first line.
- A multi-line `if`/`for`/`with`/`try` that is its own step has a blank
  line before and after it; bodies of three lines or fewer stay dense.
- Past about five paragraphs, extract a function.

```python
def export_report(path: Path, rows: Iterable[Row]) -> int:
    """Writes valid rows to a CSV report and returns how many."""
    if path.exists():
        raise FileExistsError(path)

    valid = sorted((row for row in rows if row.is_valid()), key=attrgetter("date"))

    with path.open("w", newline="") as f:
        csv.writer(f).writerows(row.as_tuple() for row in valid)

    return len(valid)
```
