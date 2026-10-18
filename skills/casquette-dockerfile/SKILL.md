---
name: casquette-dockerfile
description: >-
  Writes or reviews Dockerfiles that ship a small, non-root image. Use when
  asked to containerize a project, or to write, review, shrink or speed up a
  Dockerfile.
---
# Multi-stage Dockerfile

Build in early stages, ship only the runtime output in the last one. The final
image holds no compiler, dev dependency, package-manager cache, source tree or
secret.

## Workflow

1. Read the project first: manifest and lockfile, the pinned language version
   (`.nvmrc`, `.python-version`, `go.mod`, `rust-toolchain.toml`,
   `global.json`…), the build, test and start commands, the listening port, and
   any existing Dockerfile, `.dockerignore` or compose file. Take every version
   and command from there. If one is missing, ask once; never guess.
2. Write the Dockerfile with the layout below, then the `.dockerignore`. Check
   **Language gotchas** for that ecosystem.
3. Run the checks in **Verify**. Fix and rebuild until every one passes.
4. Report the final image size, and any check you could not run.

Reviewing an existing Dockerfile: check it against the rules and the Verify
list, list what fails with the fix for each, and change it once the user says
so. Keep the user's base images and stage names unless they cause a failure.

## Layout

```dockerfile
# syntax=docker/dockerfile:1

FROM <toolchain>:<version> AS deps
WORKDIR /app
# Dependencies before the source, so this layer survives code changes.
COPY <manifest> <lockfile> ./
RUN --mount=type=cache,target=<pkg-cache> <locked install>

FROM deps AS build
COPY . .
RUN <build>

FROM build AS test
RUN <tests>

FROM <runtime-base>:<version> AS runtime
WORKDIR /app
COPY --from=build --chown=<uid>:<gid> <build output> ./
USER <uid>
EXPOSE <port>
ENTRYPOINT ["<executable>", "<arg>"]
```

- `runtime` is the last stage, so a plain `docker build .` produces it.
  BuildKit skips stages the target does not depend on, so `test` costs nothing
  there; CI runs it with `docker build --target test .`.
- Install with the locked command (`npm ci`, `uv sync --locked`, `cargo build
  --locked`, `go mod download`). Never a resolving install that can pick new
  versions.
- Add a separate production-dependencies stage only when the runtime needs
  dependencies (Node, Python). Compiled languages copy one binary or one
  publish folder.

## Base images

- **Static binary** (Go with `CGO_ENABLED=0`, Rust on musl):
  `gcr.io/distroless/static:nonroot`. It already has CA certificates, tzdata
  and a non-root user (65532).
- **Dynamically linked binary**: `gcr.io/distroless/cc:nonroot`, or the `-slim`
  Debian image when the program needs a shell or extra system packages.
- **Interpreted or VM language**: the `-slim` (or JRE / ASP.NET runtime)
  variant of the official image, on the same version and distro as the build
  stage.
- **Alpine**: only when the project already uses it. Some Python and Node
  packages ship no musl build, so they compile from source or fail.

Pin every `FROM` to the exact version the project uses, never `latest`. Add an
`@sha256:` digest when the user wants reproducible builds and has Renovate or
Dependabot to bump it.

## Rules

- **Non-root.** End with `USER` set to a numeric UID (the image's own user, or
  one you create). Kubernetes `runAsNonRoot` rejects a non-numeric user it
  cannot verify. Give copied files to that user with `COPY --chown`, not a
  later `chown -R` that duplicates the layer.
- **Exec form.** `ENTRYPOINT ["app"]`, not `ENTRYPOINT app`. Shell form runs
  under `/bin/sh -c`, which does not forward SIGTERM, so the container gets
  killed after the stop timeout. Start the program directly, not through `npm
  start` or a wrapper script.
- **Secrets.** Never pass tokens through `ARG`, `ENV` or `COPY`: they stay in
  the image history or the build cache. Mount them for one `RUN`: `RUN
  --mount=type=secret,id=npmrc,target=/root/.npmrc npm ci`, built with `docker
  build --secret id=npmrc,src=$HOME/.npmrc .`. For private Git repos, use `RUN
  --mount=type=ssh` and `docker build --ssh default .`.
- **Caches.** Point a `--mount=type=cache` at the package manager's cache
  directory instead of deleting the cache in the same `RUN`. The cache never
  reaches a layer.
- **Layers.** Combine commands only when they must share a layer, such as
  `apt-get update && apt-get install -y --no-install-recommends …`. Do not
  chain unrelated steps just to lower the layer count; it breaks caching.
- **`.dockerignore`.** Always write one. Exclude `.git`, dependency folders
  (`node_modules`, `.venv`, `target`), build outputs, `.env*` and local secret
  files, editor and OS files, and the Dockerfile itself.
- **Build arguments.** Use `ARG` only for values that really vary between
  builds (version, target platform). Runtime configuration goes in environment
  variables set at `docker run`, not baked in.
- **HEALTHCHECK.** Add one only when the image runs under plain Docker or
  Compose; Kubernetes ignores it and uses probes. Distroless has no `curl`, so
  the check must call the program itself.

## Language gotchas

- **Node:** the official image's `node` user is UID 1000. Run `node
  dist/index.js`, not `npm start`. Production dependencies come from a separate
  `npm ci --omit=dev` stage.
- **Python:** keep the virtualenv at the same path in both stages, on the same
  Python image; its scripts use absolute paths. With uv, run `uv sync --locked
  --no-install-project` before copying the source so the dependency layer
  survives code changes.
- **Go:** `CGO_ENABLED=0` for `distroless/static`; with cgo, use
  `distroless/base`.
- **Rust:** a cache mount on `target/` is not in the layer, so copy the binary
  out in the same `RUN`. The `rust` image and `distroless/cc` must be on the
  same Debian release, or the binary needs a newer glibc than the runtime has.
- **.NET:** 8+ images ship a non-root user (`USER $APP_UID`) and listen on
  8080. Copy every `.csproj` before `dotnet restore`.
- **Java:** build with the JDK image, run on the `-jre` variant; tests belong
  in the `test` stage, so `package` skips them.

## Verify

```sh
docker build --check .                                # Dockerfile lint, must report no warnings
docker build -t app:check .
docker build --target test .                          # when a test stage exists
docker image ls app:check                             # size
docker image inspect -f '{{.Config.User}}' app:check  # numeric, not empty, not 0
docker history --no-trunc app:check                   # no secret, token or source copy
docker run -d --rm --name app-check -p <port>:<port> app:check
curl -fsS --retry 5 --retry-connrefused localhost:<port>/  # serves (or the service's own probe)
time docker stop app-check                            # stops in seconds, not after the 10s timeout
```

If Docker is not available, say so and list the checks you skipped.
