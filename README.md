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

## Side services

The repo ships a sandbox of cloud emulators and dev infrastructure that every
project can use, started with one command:

```bash
make services-up       # bring up LocalStack, MinIO, Mailhog, Jaeger, ...
make services-status
make services-down
make services-reset    # wipe persistent volumes under _services/data/
```

See [`_services/README.md`](./_services/README.md) for endpoints, env vars, and
client examples. Projects opt in by setting env vars (e.g., `AWS_ENDPOINT_URL=http://localhost:4566`).

## Catalog

<!-- CATALOG:START -->

_No projects yet. Run `make new CATEGORY=<cat> NAME=<name> LANG=<node|python>`._

<!-- CATALOG:END -->
