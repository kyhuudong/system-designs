# Shared Side Services & Recipes — Architecture Design

**Date:** 2026-06-28
**Status:** Approved (pending user review of this spec)
**Builds on:** [`2026-06-28-system-designs-repo-architecture-design.md`](./2026-06-28-system-designs-repo-architecture-design.md)

## Problem Statement

The `system-designs` repo now scaffolds many independent practice projects. As more projects accumulate, several patterns become wasteful:

- Spinning up LocalStack, MinIO, or a GCP emulator in **every** project that needs them eats RAM and slows iteration.
- Re-implementing the same small utilities (retry, structured logger, env loader) in every project is repetitive and obscures the system-design topic the project is actually about.
- There's no obvious place to capture "how do I add a Postgres replication setup" or "how do I point boto3 at LocalStack" so the lesson is preserved for next time.

We need a way to share **infrastructure** and **knowledge** across projects **without breaking the "fully independent projects, no shared code" principle** from the repo architecture spec.

## Goals

- Provide a one-command sandbox of cloud emulators and dev infrastructure shared across all projects
- Provide a library of copy-paste recipes (compose blocks + code snippets) projects can pull from
- Keep projects fully independent: nothing in a project `import`s from a shared package, no runtime dependency on shared code
- Make it obvious how to enable any side service from any project (endpoints + env conventions documented in one place)

## Non-Goals

- Shared code libraries (e.g., a `commons/python` package projects import). Explicitly rejected to preserve project independence and learning value.
- Shared instances of Postgres / Redis / Kafka. Projects practicing replication, partitioning, or consensus need their own — each project still runs its own.
- Auto-wiring side services into scaffolded projects. The scaffolder remains language-only; users opt into a side service by editing `.env` and `docker-compose.yml`.
- Multi-host / cloud-deployable side services. Local-only, matching the repo's overall scope.

## Approach Selected

**Style A + B:** Recipes (snippets, copy-paste) plus shared side services (run once, projects connect to fixed endpoints). No shared code libraries (Style C explicitly rejected).

## Architecture

### Top-Level Repo Layout (additions)

```
system-designs/
├── README.md              # updated: add "Side services & recipes" section
├── Makefile               # NEW — top-level convenience targets
├── _services/             # NEW — shared side services (cloud emulators + obs)
│   ├── docker-compose.yml
│   ├── README.md
│   └── data/              # persistent volumes (gitignored)
├── _recipes/              # NEW — copy-paste snippets
│   ├── README.md          # hand-maintained index
│   ├── compose/           # docker-compose snippets
│   ├── python/            # Python code snippets (each + test)
│   └── node/              # Node code snippets (each + test)
├── _templates/            # existing
├── scripts/               # existing
├── docs/                  # existing
└── (category folders)     # existing
```

**Updated `.gitignore`:** add `_services/data/`.

**Updated top-level `README.md`:** new section linking to `_services/README.md` and `_recipes/README.md`, plus a snippet showing `make services-up`.

### Top-Level `Makefile`

A convenience entry point. All commands target the shared services compose file.

| Target | Action |
|---|---|
| `make services-up` | `docker compose -f _services/docker-compose.yml up -d` |
| `make services-down` | `docker compose -f _services/docker-compose.yml down` |
| `make services-logs` | `docker compose -f _services/docker-compose.yml logs -f` |
| `make services-status` | `docker compose -f _services/docker-compose.yml ps` |
| `make services-reset` | `docker compose -f _services/docker-compose.yml down -v` (wipes `_services/data/`) |
| `make recipes-test` | Run tests for every code recipe (Python + Node) in isolated tmp dirs |
| `make help` | List all targets with brief descriptions |

Targeting individual services uses Docker Compose directly:
```bash
docker compose -f _services/docker-compose.yml up -d localstack mailhog
```

### Side Services (`_services/`)

#### Service Selection and Endpoints

All on shared docker network `system-designs-sandbox`. All use `restart: unless-stopped`. Persistent state under `_services/data/<service>/` (host bind mounts).

| Service | Image (pinned tag) | Host endpoint(s) | Purpose |
|---|---|---|---|
| `localstack` | `localstack/localstack:3` | `http://localhost:4566` | AWS API simulation — OSS edition: S3, SQS, SNS, DynamoDB, Lambda (basic), KMS, Secrets Manager, EventBridge, IAM, CloudWatch Logs |
| `gcloud-pubsub` | `gcr.io/google.com/cloudsdktool/google-cloud-cli:emulators` | `localhost:8085` | GCP Pub/Sub emulator |
| `gcloud-firestore` | (same image, separate container) | `localhost:8086` | GCP Firestore (Native mode) emulator |
| `azurite` | `mcr.microsoft.com/azure-storage/azurite` | `localhost:10000`/`10001`/`10002` | Azure Blob / Queue / Table |
| `minio` | `minio/minio:latest` | `http://localhost:9000` (API), `:9001` (UI) | S3-compatible object store |
| `mailhog` | `mailhog/mailhog:latest` | `localhost:1025` (SMTP), `http://localhost:8025` (UI) | Fake SMTP for testing email flows |
| `jaeger` | `jaegertracing/all-in-one:1.55` | `http://localhost:16686` (UI), `:4317` (OTLP gRPC), `:4318` (OTLP HTTP) | Distributed tracing |

**Defaults:**
- MinIO: root user `minioadmin`, root password `minioadmin`. Documented as dev-only.
- Azurite: well-known dev key (documented in `_services/README.md`).
- LocalStack: no auth. Services pre-enabled via `SERVICES=s3,sqs,sns,dynamodb,lambda,kms,secretsmanager,events`.

**Resource footprint:** approximately 2–3 GB RAM with everything up. Documented; users can comment out services they don't need or start subsets.

#### `_services/README.md` Contents

Per service:
1. **What it simulates**
2. **Endpoints** (host and inside-docker-network variants)
3. **Credentials** (where applicable)
4. **Enable in a project** — env vars to set in your project's `.env`
5. **Minimal client init** — one Python and one Node example
6. **Admin/inspect** — UI URL, CLI commands
7. **Reset just this service:** `docker compose -f _services/docker-compose.yml rm -sfv <name>`

Plus a top section covering:
- How to start/stop everything (`make services-*`)
- Network and port map
- How to connect from a project running inside its own Docker network (use `host.docker.internal` on Mac/Win; on Linux add `extra_hosts: ["host.docker.internal:host-gateway"]`)
- Resource footprint guidance

#### Conventions for Projects Using Side Services

- Endpoints are **always** read from env vars (never hard-coded), so the same code works against real cloud later. Example env keys used in `_services/README.md` examples:
  - AWS: `AWS_ENDPOINT_URL`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`
  - GCP: `PUBSUB_EMULATOR_HOST`, `FIRESTORE_EMULATOR_HOST`, `GOOGLE_CLOUD_PROJECT`
  - Azure: `AZURE_STORAGE_CONNECTION_STRING`
  - S3-compat: `S3_ENDPOINT_URL`, `S3_ACCESS_KEY`, `S3_SECRET_KEY`
  - SMTP: `SMTP_HOST`, `SMTP_PORT`
  - OTLP: `OTEL_EXPORTER_OTLP_ENDPOINT`
- Project `README.md` section 7 ("How to run") lists which side services the project depends on, with a one-liner `make services-up <name1> <name2>` reminder.

### Recipes (`_recipes/`)

A flat library of self-contained snippets. **Recipes are documentation, not dependencies.** Projects copy what they need; nothing imports from `_recipes/`.

#### Structure

```
_recipes/
├── README.md              # hand-maintained index, grouped by topic
├── compose/
├── python/
└── node/
```

#### Initial Recipe Set

The full target set below is the design goal. Plan B (`docs/superpowers/plans/2026-06-28-recipes-library.md`) implements a focused starter subset (4 utilities per language + 2 compose snippets + the test runner). Cloud-client recipes and additional compose snippets are deferred to a follow-up plan because they require the test runner to handle external dependencies (boto3, AWS SDK v3, etc.), which is a larger design problem.

**Implemented in Plan B (starter set):**
- `python/{retry,logger,env,healthcheck}.py` + tests
- `node/{retry,logger,env,healthcheck}.ts` + tests
- `compose/{postgres-with-adminer,kafka-kraft}.yml`
- `scripts/recipes-test.sh` + `make recipes-test`

**Deferred to a follow-up plan:**
- Python `timing.py`, `localstack_clients.py`, `pubsub_emulator.py`
- Node `timing.ts`, `localstack-clients.ts`, `pubsub-emulator.ts`
- Compose `postgres-replication.yml`, `redis-cluster.yml`, `kafka-3-broker.yml`, `nginx-load-balancer.yml`
- A recipe-runner extension that parses `# requires: <pkg>` headers and threads them through to uv / npm install

**`_recipes/compose/`:**
- `postgres-replication.yml` — primary + N async replicas to practice physical replication
- `postgres-with-adminer.yml` — Postgres + Adminer web UI
- `redis-cluster.yml` — 6-node Redis cluster (3 master / 3 replica)
- `kafka-kraft.yml` — single-broker Kafka in KRaft mode (no Zookeeper)
- `kafka-3-broker.yml` — 3-broker cluster for replication and partitioning practice
- `nginx-load-balancer.yml` — nginx fronting N upstream replicas (round-robin / least-conn)
- `README.md` — describes when to use each, how to copy/merge into a project's compose

**`_recipes/python/`** (each with co-located test file):
- `retry.py` — `@retry(max_attempts, base_delay, max_delay, jitter)` exponential backoff decorator
- `logger.py` — JSON-line structured logger using stdlib `logging`
- `env.py` — typed env loader: `get_str`, `get_int`, `get_bool`, `require`
- `timing.py` — `@timed` decorator + `with timing(...)` context manager
- `healthcheck.py` — minimal `/health` + `/ready` handlers built on stdlib `HTTPServer`
- `localstack_clients.py` — `boto3` clients (s3, sqs, dynamodb, …) pre-configured against LocalStack via env vars
- `pubsub_emulator.py` — `google.cloud.pubsub_v1` Publisher/Subscriber pointed at the emulator
- `README.md`

**`_recipes/node/`** (each with co-located test file):
- `retry.ts` — same as Python equivalent
- `logger.ts` — JSON-line structured logger
- `env.ts` — typed env loader with TypeScript generics
- `timing.ts` — `withTiming(...)` helper
- `healthcheck.ts` — `/health` + `/ready` handlers using `node:http`
- `localstack-clients.ts` — AWS SDK v3 clients pre-configured against LocalStack
- `pubsub-emulator.ts` — `@google-cloud/pubsub` against the emulator
- `README.md`

External-dependency recipes (the cloud clients) declare their npm/pip dep in the file header so users know what to install in their project.

#### Per-Recipe Convention

Every code-snippet file starts with a top-of-file comment block:

```python
# Recipe: <name>
# Copy this file into your project's src/ and import as needed.
# Stdlib-only.  (or:  Requires: boto3>=1.34)
# Usage:
#   <minimal example>
```

Every compose snippet starts with a comment header explaining what it provides and how to merge into a project's `docker-compose.yml`.

#### `_recipes/README.md`

Hand-maintained index grouped by topic for "I want to do X" lookup:

```markdown
## Storage
- compose/postgres-replication.yml  — Postgres primary + replicas
- compose/postgres-with-adminer.yml — Postgres + web UI

## Messaging
- compose/kafka-kraft.yml       — single-broker Kafka
- compose/kafka-3-broker.yml    — 3-broker cluster for replication/partitioning

## Cloud sandboxes
- python/localstack_clients.py  — boto3 → LocalStack
- node/localstack-clients.ts    — AWS SDK v3 → LocalStack
- python/pubsub_emulator.py     — Pub/Sub → emulator
- node/pubsub-emulator.ts       — Pub/Sub → emulator

## App utilities
- python/retry.py, node/retry.ts        — exponential backoff
- python/logger.py, node/logger.ts      — JSON-line logger
- python/env.py, node/env.ts            — typed env loader
- python/timing.py, node/timing.ts      — timing helpers
- python/healthcheck.py, node/healthcheck.ts — /health + /ready
```

#### Recipe Tests

Each code recipe has a co-located minimal test (`retry.test.ts`, `test_retry.py`, …) covering at least the happy path and one edge case (e.g., for `retry`: succeeds on first try, succeeds after N failures, gives up after max attempts).

A repo-level `make recipes-test` target runs every recipe's tests in an isolated tmp dir using ephemeral runners:
- Python: `uv run --with pytest pytest <tmpdir>/<recipe>` (or simply `python -m pytest` in a `uv tool run` env)
- Node: copy recipe + test to a tmp dir with a minimal `package.json` declaring vitest, run `pnpm dlx vitest run`

This keeps recipes verified without requiring a top-level `package.json` / `pyproject.toml`.

## Data Flow

- **Side services:** projects connect over `localhost` (when running via `make dev`) or `host.docker.internal` (when running in their own Docker compose). No cross-project state coupling intended — projects should namespace their resources (e.g., S3 bucket per project).
- **Recipes:** no runtime data flow. Users copy files into their project; the copy becomes part of the project's code.

## Error Handling

- **`Makefile` targets:** fail fast with non-zero exit if `_services/docker-compose.yml` is missing or Docker isn't running.
- **`make services-reset`** prompts for confirmation before wiping `_services/data/` (use `make services-reset-force` to skip the prompt for scripts).
- **`make recipes-test`** runs every recipe, reports a per-recipe pass/fail summary, exits non-zero if any failed.
- **Side services themselves:** rely on each image's defaults; failures surface via `make services-logs`.

## Testing

- **`_services/docker-compose.yml`:** a smoke test in `scripts/tests/test_services_compose.sh` runs `docker compose -f _services/docker-compose.yml config --quiet` to validate the file (no actual `up` — that's slow).
- **Top-level `Makefile`:** smoke test in `scripts/tests/test_top_makefile.sh` verifies every documented target exists and that `make help` lists them.
- **Recipes:** every code recipe ships with its own test file. `make recipes-test` runs the full set.
- All new tests run via the existing `scripts/tests/run-tests.sh` harness.

## Trade-offs & Alternatives Considered

| Decision | Chosen | Alternative | Why |
|---|---|---|---|
| Shared code library (Style C) | Rejected | Add `commons/python` + `commons/node` packages | Breaks "fully independent" principle; defeats *learning* purpose (every project becomes "import the magic"); creates versioning headaches |
| Recipe organization | By kind (`compose/`, `python/`, `node/`) | By topic (`aws/`, `observability/`, …) or hybrid | Easier to scan ("I need a Python file" → one folder); the README index handles topic-based discovery |
| Side service lifecycle | Top-level Makefile, single shared compose file | Per-service folder with its own compose | One file is simpler to understand and maintain; selective startup still works via `docker compose up <name>` |
| State persistence | Persist by default, explicit reset | Wipe by default | Saves time when iterating on a project; resetting is one command |
| Shared infra components (PG/Redis/Kafka) | Each project still runs its own | Add to `_services/` too | Projects practicing replication/partitioning/consensus need their own dedicated instance |
| Scaffolder integration | Manual opt-in (edit `.env` per project) | `--with=localstack,jaeger` flag | YAGNI for v1; can add later if friction emerges |
| Resource footprint | Everything optional, document RAM cost | Trim starter set | All emulators are useful; users start subsets via `docker compose up <name>` |

## Open Questions

None at design time. Specific recipe implementations (e.g., exact retry signature, exact env-loader API) are implementation choices made in the plan.

## Out of Scope (Future)

- Auto-wiring side services into scaffolded projects (`new-project.sh --with-localstack`)
- Web-based service dashboard / status page
- Adding shared instances of Postgres/Redis/Kafka to `_services/` (deliberately excluded)
- `commons/` shared code libraries (deliberately excluded)
- Additional recipes (will accrue organically as practice projects need them)
- CI integration (`make recipes-test` in GitHub Actions)
- Docker-compose profiles to group services (e.g., `--profile aws`, `--profile gcp`) — could be added if the service set grows
