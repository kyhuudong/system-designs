# System Designs Repo — Architecture Design

**Date:** 2026-06-28
**Status:** Approved (pending user review of this spec)

## Problem Statement

The `system-designs` repo will house many hands-on backend practice projects (classic system design problems, real-world app backends, and distributed-systems primitives) in a single Git repository. We need an architecture that:

- Keeps each project fully independent (no shared code, no cross-project coupling)
- Stays consistent across many projects so context-switching is cheap
- Makes spinning up a new project nearly frictionless
- Captures the *design* of each system (not just the code), since the learning value is in articulating problem, requirements, trade-offs, and architecture
- Runs entirely locally via Docker Compose
- Supports both Node.js (TypeScript) and Python projects

## Goals

- One repo, many projects, categorized by topic
- Per-project: design doc + code + docker-compose, all self-contained
- Bootstrap a new project in under a minute via a scaffolding script
- Uniform `make` interface across projects regardless of language

## Non-Goals

- Shared libraries or cross-project code reuse
- Monorepo tooling (Nx, Turborepo, Bazel)
- Cloud/Kubernetes deployment
- CI/CD pipelines (out of scope for v1; can be added later per-project)
- Auto-maintained catalog (kept manual on purpose)

## Approach Selected

**Option B — Templates + scaffolding.** Provides consistency and speed without imposing heavy ceremony. Each project is independent, follows a shared structural convention, and is generated from a per-language template via a scaffolding script. Architecture Decision Records and cross-cutting docs are deferred (can be added per-project where warranted).

## Architecture

### Top-Level Repo Layout

```
system-designs/
├── README.md              # catalog/index of all projects (hand-maintained)
├── _templates/            # scaffolding templates (sorted to top via underscore prefix)
│   ├── node/
│   └── python/
├── scripts/
│   └── new-project.sh     # bootstrap a new project
├── caching/               # category: caches, eviction policies, CDNs
├── messaging/             # category: queues, pub/sub, event streams
├── databases/             # category: KV stores, indexes, replication, sharding
├── primitives/            # category: rate limiters, consensus, bloom filters
├── apps/                  # category: full-app backends (URL shortener, chat, etc.)
├── .gitignore
└── .editorconfig
```

**Categories** are created lazily — only materialized when the first project in that category is scaffolded. New categories can be added freely (e.g., `observability/`, `networking/`, `storage/`).

**Naming:** all folder names are `kebab-case`. Project folders use descriptive names (e.g., `caching/distributed-lru-cache`, `apps/url-shortener`).

### Per-Project Structure

Every project is a self-contained directory with this shape:

```
<category>/<project-name>/
├── README.md              # design doc following the standard template
├── docs/
│   └── diagrams/          # PNG/SVG/mermaid sources, used when warranted
├── src/                   # source code
├── tests/                 # tests
├── Dockerfile             # app image
├── docker-compose.yml     # app + dependencies (redis, postgres, kafka, etc.)
├── .env.example           # documented env variables (no secrets)
├── Makefile               # standard targets: up, down, test, lint, logs, shell
└── (language-specific)    # package.json + pnpm-lock.yaml, OR pyproject.toml + uv.lock
```

### Design Doc Template (README.md)

Every project's `README.md` follows this structure:

1. **Problem statement** — what we're building and why
2. **Requirements** — functional + non-functional (scale targets, latency, consistency, availability)
3. **API / interface** — HTTP endpoints, message schemas, CLI, etc.
4. **Architecture** — components and data flow (mermaid diagram inline when useful)
5. **Data model** — schemas, indexes, partitioning, retention
6. **Trade-offs & alternatives** — what was considered, what was chosen, why
7. **How to run** — `make up`, `make test`, etc.
8. **What I learned** — short retrospective written after building it

### Standard Makefile Targets

All projects expose the same `make` interface, regardless of language:

| Target | Purpose |
|---|---|
| `make up` | Start the app + dependencies via docker-compose |
| `make down` | Stop and remove containers |
| `make test` | Run the test suite |
| `make lint` | Run linter/formatter |
| `make logs` | Tail container logs |
| `make shell` | Open a shell inside the app container |

This eliminates the need to remember language-specific commands when context-switching.

### Node.js Template (`_templates/node/`)

- **Language:** TypeScript
- **Package manager:** `pnpm` (lockfile generated and committed per-project on first `make install`; not shipped in the template)
- **Test runner:** `vitest`
- **Lint/format:** `eslint` + `prettier`
- **Runtime image:** `node:20-alpine` (multi-stage Dockerfile)
- **Scaffold contents:**
  - `Dockerfile`, `docker-compose.yml` (app service + commented blocks for redis/postgres/kafka)
  - `Makefile` (standard targets wired to pnpm/vitest/eslint)
  - `README.md` pre-filled with the design doc template
  - `src/index.ts` (minimal HTTP server placeholder)
  - `tests/smoke.test.ts` (basic passing test)
  - `package.json`, `tsconfig.json`, `.eslintrc`, `.prettierrc`
  - `.env.example` (the scaffolder also creates a working `.env` from it)

### Python Template (`_templates/python/`)

- **Language:** Python 3.12
- **Package manager:** `uv` (lockfile generated and committed per-project on first `make install`; not shipped in the template)
- **Test runner:** `pytest`
- **Lint/format:** `ruff`
- **Runtime image:** `python:3.12-slim` (multi-stage Dockerfile)
- **Scaffold contents:**
  - `Dockerfile`, `docker-compose.yml` (app service + commented blocks for redis/postgres/kafka)
  - `Makefile` (standard targets wired to uv/pytest/ruff)
  - `README.md` pre-filled with the design doc template
  - `src/main.py` (minimal HTTP server placeholder)
  - `tests/test_smoke.py` (basic passing test)
  - `pyproject.toml`
  - `.env.example` (the scaffolder also creates a working `.env` from it)

### Scaffolding Script (`scripts/new-project.sh`)

**Usage:**
```bash
./scripts/new-project.sh <category> <name> <node|python>
# example:
./scripts/new-project.sh caching distributed-lru-cache node
```

**Behavior:**
1. Validate inputs:
   - `<lang>` must be `node` or `python`
   - `<name>` must be kebab-case
   - `<category>` is created if it doesn't exist (warns the user)
   - Fails if `<category>/<name>/` already exists
2. Copy `_templates/<lang>/` to `<category>/<name>/`
3. Replace placeholders in copied files:
   - `__PROJECT_NAME__` → `<name>`
   - `__CATEGORY__` → `<category>`
   - `__PROJECT_TITLE__` → Title Case from kebab-case
4. Print next steps:
   - `cd <category>/<name>`
   - Edit `README.md` to write the design
   - `make up` to start
5. **Does NOT auto-commit** — the user commits when ready.

### Top-Level Catalog (`README.md`)

Hand-maintained Markdown index, grouped by category:

```markdown
# system-designs

Hands-on practice repo for backend system design.
See [docs/superpowers/specs/](./docs/superpowers/specs/) for the repo architecture.

## caching
| Project | Stack | Status | Doc |
|---|---|---|---|
| distributed-lru-cache | Node | 🚧 in progress | [link](./caching/distributed-lru-cache/README.md) |

## apps
| Project | Stack | Status | Doc |
|---|---|---|---|
| url-shortener | Python | ✅ done | [link](./apps/url-shortener/README.md) |
```

**Status values:** `📝 planned`, `🚧 in progress`, `✅ done`, `🧊 paused`, `🗑️ archived`.

Updating the catalog is a manual step when finishing or abandoning a project. Kept manual so the catalog stays an intentional reflection of progress.

## Repo-Level Files

- **`.gitignore`** — covers `node_modules/`, `__pycache__/`, `.venv/`, `dist/`, `.env`, `.DS_Store`, docker volumes
- **`.editorconfig`** — consistent indentation, line endings, trim trailing whitespace

## Data Flow

There is no cross-project data flow. Each project's `docker-compose.yml` defines its own isolated network and volumes. Projects do not communicate with each other.

## Error Handling

- **Scaffolding script:** fail fast with clear error messages on invalid input; never overwrite an existing project
- **Per-project:** error handling is each project's own concern, documented in its design doc

## Testing

- **Repo-level:** the scaffolding script should be testable — at minimum, a smoke test that scaffolds a throwaway project into a temp dir and verifies the file tree
- **Per-project:** each template includes a passing smoke test so `make test` works immediately after scaffolding

## Trade-offs & Alternatives Considered

| Decision | Chosen | Alternative | Why |
|---|---|---|---|
| Project independence | Fully independent | Shared libs / true monorepo | Practice repo — focus is on learning each system end-to-end, not on cross-cutting abstractions |
| Top-level grouping | By topic | Flat, by language, sequenced | Topic grouping aids discovery and matches how system design concepts are typically organized |
| Catalog maintenance | Manual | Auto-generated from folder scan | Forces intentional reflection on status; trivial automation can be added later if it becomes painful |
| Languages | Node + Python | Polyglot free-for-all, or single language | Two languages cover most BE practice scenarios; constrains template maintenance |
| Deployment | Local Docker Compose only | Include k8s/IaC | Out of scope; keeps friction low |
| ADRs / cross-cutting docs | Deferred | Required per project | Avoid ceremony; can be added per-project where warranted |

## Open Questions

None at design time. Implementation details (specific Dockerfile contents, exact Makefile wiring, .gitignore contents) will be decided during implementation.

## Out of Scope (Future)

- CI/CD per project (e.g., GitHub Actions running `make test`)
- Repo-level `docs/` for cross-cutting learning notes
- Auto-generated catalog
- Architecture Decision Records (ADR) templates
- Pre-commit hooks
- Devcontainer for one-step environment setup
