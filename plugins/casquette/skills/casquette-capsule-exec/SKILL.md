---
name: casquette-capsule-exec
description: >-
  Runs commands in a project's devcontainer with `capsule exec`. Use when asked
  to test, build or reproduce something in the container or with capsule, when
  a host toolchain is missing, or when a change needs a clean Linux environment.
---
# capsule exec

The user's instructions take precedence over this skill.

`capsule exec` starts (or reuses) the devcontainer for the current directory, runs one command in it, and returns that command's output and exit code. It is the non-interactive way in: use it for every command you want to run inside the container.

Run `command -v capsule` first. When it prints nothing, capsule is not installed: follow "Check that capsule is installed" in the `casquette-capsule` skill before anything else.

## Pick the target

Run from the project root. The container is keyed by the host directory, so the same directory always reaches the same container, and a different directory creates a new one.

- `.devcontainer/devcontainer.json` exists in the current directory: give no template name. Every positional argument is the command, even a word that matches a template name.
- No local `.devcontainer/`: the first positional argument is a stored template name. Run `capsule list` to see the names, and pick the one whose toolchain fits the project (or ask the user when several fit).

## Command form

Always write it like this:

```sh
capsule exec -q -- <cmd> [args...]              # local .devcontainer/
capsule exec -q <template> -- <cmd> [args...]   # stored template
```

- `-q` hides the `devcontainer up` log, so stdout is the command's own output. If startup fails, capsule prints the captured log anyway.
- `--` is required. Capsule parses its own flags (`-q`, `--quiet`, `--rebuild`, `--recreate`) anywhere on the line, so without `--` the command `pytest -q` silently loses its `-q`, and `make --rebuild` destroys the container.
- The command runs directly, without a shell. For pipes, `&&`, redirects, globs or `$VAR`, wrap it: `capsule exec -q -- sh -c 'cd sub && make'`.

## How the container behaves

- **Workspace is live.** The host directory is mounted at `/workspaces/<dirname>`, and each command starts there. Edit files on the host with your normal tools; the container sees the change immediately. No copy step.
- **Each call is a fresh process.** `cd`, `export` and shell state do not carry over between calls. Chain dependent steps in one `sh -c`.
- **Container state persists.** Packages installed with `apt`, `pip` or `npm -g`, and files outside the workspace, survive between calls until the container is recreated. Install a missing tool once, then reuse it.
- **Host env is not forwarded.** Only variables from `~/.config/capsule/config.toml` `[env]`, the devcontainer's `remoteEnv`, `UID` and `GID` reach the container. Pass anything else inline: `-- env FOO=1 make`.
- **The exit code is the command's.** Read success or failure from it and report it. A pipe such as `| tail` replaces it with the last command's.
- **The user is the image's user** (`vscode` on Microsoft images), not root. Use `sudo` when the image provides it.

## Timing

The first call for a directory pulls the image and runs `postCreateCommand`: allow several minutes (use a 10-minute timeout, or run it in the background). Later calls take a few seconds. To warm the container before real work: `capsule exec -q [template] -- true`.

## Recreating

`--recreate` destroys the container and creates a new one from the current `devcontainer.json`. `--rebuild` does the same and also rebuilds a Dockerfile-based image without the build cache. Use either only when `devcontainer.json` or the capsule mounts changed, a Dockerfile image's cached layers are stale (an old `apt-get update`, a moved `git clone`), or the container is broken. Both wipe all installed state, so get the user's agreement first. Put it before `--`: `capsule exec -q --recreate -- true`.

## Stay non-interactive

Commands that wait for input hang the call, so run one-shot forms. Leave the container running between calls; reuse is the point.

## Failures

- `devcontainer CLI not found`, or any other setup problem: follow "First-time setup" in the `casquette-capsule` skill.
- `No .devcontainer/devcontainer.json found and no template name given`: pass a template name, or set the project up with the `casquette-capsule` skill.
- `devcontainer up failed`: read the printed log. Common causes are a bad `devcontainer.json`, a failing `postCreateCommand`, or a stopped container runtime.
