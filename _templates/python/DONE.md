# DONE.md — __PROJECT_TITLE__

Tick every box before declaring this project finished and setting
`.status` to `done`. This is the agent's stopping condition.

## Design
- [ ] `README.md` §1 (Problem statement) — filled, not placeholder
- [ ] `README.md` §2 (Requirements) — functional + non-functional with numeric NFRs
- [ ] `README.md` §3 (API / interface) — concrete endpoints / schemas
- [ ] `README.md` §4 (Architecture) — references the diagrams below
- [ ] `README.md` §5 (Data model) — schemas, indexes, partitioning
- [ ] `README.md` §6 (Trade-offs & alternatives) — at least one row in the table

## Diagrams
- [ ] `docs/diagrams/00-context.svg` — rendered from `.mmd` source via `make diagram`
- [ ] `docs/diagrams/01-sequence-happy-path.svg` — rendered

## Design artifacts
- [ ] `docs/requirements.md` — filled
- [ ] `docs/capacity-estimation.md` — back-of-envelope numbers present
- [ ] `docs/failure-modes.md` — at least 3 rows
- [ ] `docs/adr/` — at least one ADR for a real decision (not the template itself)

## Code & tests
- [ ] `make install` succeeds on a fresh clone
- [ ] `make test` passes
- [ ] `make lint` passes
- [ ] `make up` brings the project up; basic happy-path request works
- [ ] `make down` cleans up

## Reflection
- [ ] `README.md` §8 ("What I learned") — at least 3 substantive sentences,
      not boilerplate

## Catalog
- [ ] `.status` set to `done`
- [ ] Top-level catalog regenerated: `make catalog` from repo root
