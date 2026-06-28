# system-designs

Hands-on practice repo for building backend systems: classic system design problems,
real-world app backends, and distributed-systems primitives.

Every project is self-contained: design doc + code + `docker-compose.yml`, run locally.

**Architecture:** [`docs/superpowers/specs/2026-06-28-system-designs-repo-architecture-design.md`](./docs/superpowers/specs/2026-06-28-system-designs-repo-architecture-design.md)

## Quick start

Spin up a new project:

```bash
./scripts/new-project.sh <category> <project-name> <node|python>
# example:
./scripts/new-project.sh caching distributed-lru-cache node
```

Then:

```bash
cd <category>/<project-name>
make up      # start app + dependencies
make test    # run tests
make down    # stop
```

## Status legend

`📝 planned` · `🚧 in progress` · `✅ done` · `🧊 paused` · `🗑️ archived`

## Catalog

<!-- Update this catalog manually when you finish or abandon a project. -->

### caching
_No projects yet._

### messaging
_No projects yet._

### databases
_No projects yet._

### primitives
_No projects yet._

### apps
_No projects yet._
