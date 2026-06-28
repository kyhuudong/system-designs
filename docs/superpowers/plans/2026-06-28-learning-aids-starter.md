# Learning Aids — Starter (Plan F) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the design-thinking artifacts (ADRs, requirements, capacity estimation, failure modes) part of the standard project scaffold, plus add a small set of repo-wide system-design cheat sheets under `docs/learning/`. Extend `make design-check` to enforce the new per-project artifacts exist.

**Architecture:** Pure documentation. Per-project template additions (4 files + 1 ADR template), repo-level `docs/learning/` (3 cheat sheets + index), one tweak to `make design-check` in both Makefiles. No new scripts.

**Tech Stack:** Markdown. Bash for tests.

**Spec:** [`docs/superpowers/specs/2026-06-28-agent-enablement-diagrams-learning-design.md`](../specs/2026-06-28-agent-enablement-diagrams-learning-design.md) (Bundle F, starter scope only — F2 deferred to a follow-up plan)

**Depends on:** Plans D and E landed.

**Scope decision:** Spec lists a much larger F set; this plan implements the **starter subset**. Deferred to a follow-up plan (F2): pattern glossary, CAP/PACELC notes, problems index, load-test recipe, `make finalize` automation, postmortem template.

---

## File Map

**Create (repo-level):**
- `docs/learning/README.md` — index
- `docs/learning/latency-numbers.md`
- `docs/learning/consistency-models.md`
- `docs/learning/back-of-envelope.md`

**Create (per-project templates, applied to BOTH `_templates/node/` and `_templates/python/`):**
- `docs/adr/0000-template.md` — ADR template
- `docs/adr/README.md` — how to use ADRs in this project
- `docs/requirements.md` — functional + NFR worksheet
- `docs/capacity-estimation.md` — back-of-envelope worksheet
- `docs/failure-modes.md` — failure-mode table starter

**Modify (per-project templates):**
- `Makefile` — extend `design-check` to also assert the new docs exist and are non-trivial
- `README.md` — §7 (How to run) gets a pointer to the design artifacts under `docs/`

**Modify (repo-level):**
- `AGENTS.md` — extend "Read these before you change code" with the new learning links

**Modify (tests):**
- `scripts/tests/test_new_project.sh` — extend expected-files lists, add substitution coverage
- `scripts/tests/test_design_check.sh` — extend the pass/fail coverage for the new gates

---

## Task 1: Per-project ADR template + index — Node side

**Files:**
- Create: `_templates/node/docs/adr/0000-template.md`
- Create: `_templates/node/docs/adr/README.md`

- [ ] **Step 1: Create directory and ADR template**

```bash
mkdir -p /Users/dong.kyh/works/system-designs/_templates/node/docs/adr
```

`_templates/node/docs/adr/0000-template.md`:

```markdown
# ADR-NNNN: <short title>

**Date:** YYYY-MM-DD
**Status:** Proposed | Accepted | Superseded by ADR-MMMM

## Context

What is the situation that requires a decision? What forces are at play —
technical, business, organizational? Be concrete; cite measurements,
existing constraints, deadlines.

## Decision

What did we decide to do? State it in one sentence first, then expand.

## Consequences

### Positive
- ...
- ...

### Negative
- ...
- ...

### Neutral
- ...

## Alternatives considered

For each meaningful alternative:

### <Alternative A>
- Pros: ...
- Cons: ...
- Why not chosen: ...

### <Alternative B>
- Pros: ...
- Cons: ...
- Why not chosen: ...

## References

- Links to related ADRs, design docs, RFCs, prior art
```

- [ ] **Step 2: Create `_templates/node/docs/adr/README.md`**

```markdown
# Architecture Decision Records — __PROJECT_TITLE__

Capture every **non-obvious** decision as an ADR. Three signals that a
decision is worth an ADR:

1. **You will be asked "why"** by a teammate, your future self, or an
   AI agent six months from now.
2. **There were multiple plausible options** — not just one obvious path.
3. **Reversing the decision would be expensive** — schema, public API,
   data format, deployment topology.

## Format

- Filename: `NNNN-<kebab-title>.md` (4-digit zero-padded, monotonic)
- Template: copy [`0000-template.md`](./0000-template.md)
- Status flows: `Proposed → Accepted` (most common) or
  `Accepted → Superseded by ADR-MMMM`
- Don't delete superseded ADRs — they're the audit trail

## When NOT to write an ADR

- Style choices (prettier/ruff handles those)
- Implementation details that don't surface in any interface
- Decisions that can be reversed in under an hour

## Index

_Add a row when you accept a new ADR._

| # | Title | Status | Date |
|---|---|---|---|
| _none yet_ | | | |
```

- [ ] **Step 3: Commit**

```bash
cd /Users/dong.kyh/works/system-designs
git add _templates/node/docs/adr/
git commit -m "feat(templates/node): add ADR template and per-project ADR README

0000-template.md follows the Nygard-lite shape: Context / Decision /
Consequences (+/-/neutral) / Alternatives Considered / References.

docs/adr/README.md explains when to write an ADR (and when not to),
the filename convention, and provides a 'recent ADRs' table the user
maintains as decisions accumulate.

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Task 2: Per-project ADR template — Python side

**Files:**
- Create: `_templates/python/docs/adr/0000-template.md`
- Create: `_templates/python/docs/adr/README.md`

- [ ] **Step 1: Create directory and copy the same files from Task 1**

```bash
mkdir -p /Users/dong.kyh/works/system-designs/_templates/python/docs/adr
```

Copy `_templates/node/docs/adr/0000-template.md` and `_templates/node/docs/adr/README.md` verbatim into the Python paths. No stack-specific text in either.

- [ ] **Step 2: Commit**

```bash
cd /Users/dong.kyh/works/system-designs
git add _templates/python/docs/adr/
git commit -m "feat(templates/python): add ADR template (mirror of Node template)

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Task 3: Per-project worksheets (requirements, capacity, failure-modes) — Node side

**Files:**
- Create: `_templates/node/docs/requirements.md`
- Create: `_templates/node/docs/capacity-estimation.md`
- Create: `_templates/node/docs/failure-modes.md`

- [ ] **Step 1: Create `_templates/node/docs/requirements.md`**

```markdown
# Requirements — __PROJECT_TITLE__

> Fill BEFORE writing code. Vague requirements produce vague systems.

## Functional requirements

What must the system **do**? One line per capability. Add an example
input/output where it clarifies.

- [ ] _Capability 1_
- [ ] _Capability 2_
- [ ] _Capability 3_

## Non-functional requirements

What must the system **be**? Numeric targets only — "fast" is not a
requirement, "p99 < 50 ms at 1k QPS" is.

### Scale

| Dimension | Target | Notes |
|---|---|---|
| Concurrent users | _N_ | |
| Requests per second (avg) | _N_ | |
| Requests per second (peak) | _N_ | |
| Data volume (today) | _N MB/GB_ | |
| Data growth | _N MB/day_ | |
| Read:write ratio | _N:1_ | |

### Latency

| Operation | p50 | p95 | p99 |
|---|---|---|---|
| _primary read_ | _X ms_ | _Y ms_ | _Z ms_ |
| _primary write_ | _X ms_ | _Y ms_ | _Z ms_ |

### Availability and durability

- **Availability target:** _e.g. 99.9% (≤ 8h45m downtime/year)_
- **Durability target:** _e.g. 99.999999999% (S3-equivalent)_
- **Recovery point objective (RPO):** _max acceptable data loss in
  minutes_
- **Recovery time objective (RTO):** _max acceptable downtime in
  minutes during disaster recovery_

### Consistency

- _strong / eventual / read-your-writes / causal — and where each
  applies_

### Security and compliance

- _auth model, PII handling, regulatory constraints if any_

## Out of scope (explicit non-requirements)

- _List things you DELIBERATELY don't support, so trade-offs are
  visible_
```

- [ ] **Step 2: Create `_templates/node/docs/capacity-estimation.md`**

```markdown
# Capacity Estimation — __PROJECT_TITLE__

> Back-of-envelope numbers. Off by 2× is fine; off by 100× is not.
> See [`docs/learning/back-of-envelope.md`](../../docs/learning/back-of-envelope.md)
> for methodology and worked examples.

## Inputs

- **DAU (daily active users):** _N_
- **Sessions per DAU per day:** _N_
- **Avg requests per session:** _N_

## Derived load

| Metric | Calculation | Value |
|---|---|---|
| Daily requests | DAU × sessions × reqs/session | _N_ |
| Avg RPS | daily ÷ 86400 | _N_ |
| Peak RPS (3× avg, rule of thumb) | avg × 3 | _N_ |

## Storage

| Item | Bytes per item | Items today | Items in 1 year | Storage |
|---|---|---|---|---|
| _primary entity_ | _N_ | _N_ | _N_ | _GB_ |
| _index_ | _N_ | _N_ | _N_ | _GB_ |
| _log/event stream_ | _N_ | _N_ | _N_ | _GB_ |

## Bandwidth

| Direction | Avg payload | RPS | Bandwidth |
|---|---|---|---|
| Ingress | _bytes_ | _N_ | _MB/s_ |
| Egress  | _bytes_ | _N_ | _MB/s_ |

## Single-node limits

What does ONE machine of your chosen size handle?

- **CPU:** _N cores → ~K req/s assuming X ms CPU per req_
- **Memory:** _N GB → fits the working set if < N items × N bytes_
- **Disk IO:** _N MOPS or N GB/s_
- **Network:** _N Gbps_

## When do you need to scale?

- **Read scaling triggers at:** _N RPS / N GB → add replicas / add cache_
- **Write scaling triggers at:** _N RPS / N GB / N TB → shard by …_

## Cost rough order

(Optional — useful for "is this idea even sane.")

| Resource | Quantity | Unit cost | Monthly |
|---|---|---|---|
| _compute_ | _N nodes_ | _$N_ | _$N_ |
| _storage_ | _N TB_   | _$N_ | _$N_ |
| _bandwidth_ | _N TB egress_ | _$N_ | _$N_ |
```

- [ ] **Step 3: Create `_templates/node/docs/failure-modes.md`**

```markdown
# Failure Modes — __PROJECT_TITLE__

> "What breaks first, and what happens when it does?"
> Identify the top failure modes BEFORE the system is built so you
> design against them, not bolt on retries at the end.

## Failure inventory

| Failure | Likelihood | Blast radius | Detection | Mitigation |
|---|---|---|---|---|
| _Datastore unreachable_ | Medium | All writes fail; reads from cache may succeed | Health check on `/ready`; alerts on 5xx rate | Retry with backoff; circuit breaker; degrade to read-only mode |
| _Cache cold start / failure_ | Low–Medium | Tail latency spikes; load on datastore × N | p99 latency jumps; cache miss rate | Pre-warm on deploy; bound concurrent backend calls |
| _Single instance crash_ | Medium | In-flight requests fail | Process exit; orchestrator restarts | Run N >= 2 instances; idempotent writes |
| _Slow downstream dependency_ | Medium | Resource exhaustion as requests pile up | p99 dependency latency | Hard timeout; bulkhead; load shedding |
| _Bad deploy_ | Low | Errors at deploy time | Smoke test post-deploy; error rate | Auto-rollback on smoke-test failure; canary |
| _Data corruption (logical bug)_ | Low | Permanent until rolled forward | Schema validation; sampled audit | Backups + point-in-time-restore; immutable event log |
| _Auth provider down_ | Low | All auth fails | Auth dependency health | Cache valid tokens for grace window; fail open vs closed (choose explicitly) |
| _Traffic spike (N× normal)_ | Medium | Saturation; cascading timeouts | Saturation metrics | Rate limit; load shedding; autoscale (slow); request prioritization |

(Delete rows that don't apply; add rows specific to this system.)

## Degradation strategy

When the system is partially broken, what does it do?

- **Worst-case acceptable behavior:** _e.g. "read-only mode for at most
  1 hour; reject writes with 503 and clear retry-after header"_
- **What we will NOT do:** _e.g. "we won't serve stale data older than
  60 s"_

## Failure injection / chaos

What scenarios should we periodically rehearse?

- _Kill the datastore connection mid-request_
- _Add 500 ms latency to all calls to <service>_
- _Drop 1% of packets_
```

- [ ] **Step 4: Commit**

```bash
cd /Users/dong.kyh/works/system-designs
git add _templates/node/docs/requirements.md _templates/node/docs/capacity-estimation.md _templates/node/docs/failure-modes.md
git commit -m "feat(templates/node): add design worksheets (requirements, capacity, failure-modes)

Three required-before-code worksheets per project:
- requirements.md: functional + numeric NFRs (scale, latency,
  availability, durability, consistency, security)
- capacity-estimation.md: back-of-envelope load and storage math with
  derived RPS / storage / bandwidth + single-node-limit awareness
- failure-modes.md: failure × likelihood × blast radius × detection ×
  mitigation table, plus explicit degradation strategy and chaos
  scenarios

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Task 4: Per-project worksheets — Python side

Same three files, identical content.

**Files:**
- Create: `_templates/python/docs/requirements.md`
- Create: `_templates/python/docs/capacity-estimation.md`
- Create: `_templates/python/docs/failure-modes.md`

- [ ] **Step 1: Copy the three Task 3 files into the Python template**

Copy verbatim — no stack-specific text in any of these files. After copying, the Python template's `docs/` should look the same as Node's.

- [ ] **Step 2: Commit**

```bash
cd /Users/dong.kyh/works/system-designs
git add _templates/python/docs/
git commit -m "feat(templates/python): add design worksheets (mirror of Node template)

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Task 5: Extend `make design-check` to assert new artifacts

**Files:**
- Modify: `_templates/node/Makefile`
- Modify: `_templates/python/Makefile`

- [ ] **Step 1: Update the `design-check` recipe in `_templates/node/Makefile`**

Locate the existing `design-check:` rule (added in Plan E). Replace its body with a version that also checks the new artifacts:

```makefile
design-check:
	@fail=0; \
	for s in 00-context 01-sequence-happy-path; do \
	  if [ ! -f "docs/diagrams/$$s.svg" ]; then \
	    echo "design-check: missing docs/diagrams/$$s.svg (run 'make diagram')" >&2; \
	    fail=1; \
	  fi; \
	done; \
	for section in "## 1. Problem statement" "## 2. Requirements" "## 4. Architecture"; do \
	  if ! grep -qF "$$section" README.md; then \
	    echo "design-check: README.md missing section '$$section'" >&2; \
	    fail=1; \
	  fi; \
	done; \
	if grep -qE "_What are we building and why\?_|_List the things this system must do_" README.md; then \
	  echo "design-check: README.md still contains template placeholder text" >&2; \
	  echo "             (sections 1 or 2 not yet filled)" >&2; \
	  fail=1; \
	fi; \
	for doc in docs/requirements.md docs/capacity-estimation.md docs/failure-modes.md; do \
	  if [ ! -f "$$doc" ]; then \
	    echo "design-check: missing $$doc" >&2; \
	    fail=1; \
	  fi; \
	done; \
	if grep -qE "_Capability 1_|_primary entity_|_Datastore unreachable_" docs/requirements.md docs/capacity-estimation.md docs/failure-modes.md 2>/dev/null; then \
	  echo "design-check: worksheet(s) under docs/ still contain template placeholder text" >&2; \
	  fail=1; \
	fi; \
	if [ ! -d "docs/adr" ] || [ -z "$$(ls docs/adr/[0-9]*.md 2>/dev/null | grep -v 0000-template.md)" ]; then \
	  echo "design-check: no real ADRs in docs/adr/ (the 0000-template.md doesn't count)" >&2; \
	  fail=1; \
	fi; \
	if [ $$fail -eq 0 ]; then echo "design-check: OK"; else exit 1; fi
```

- [ ] **Step 2: Apply the same body to `_templates/python/Makefile`**

Replace the existing `design-check:` rule in the Python template with the exact same body from Step 1 — no language-specific content.

- [ ] **Step 3: Sanity check both Makefiles parse**

```bash
for lang in node python; do
  TMP=$(mktemp -d)
  cp -R "/Users/dong.kyh/works/system-designs/_templates/$lang" "$TMP/check"
  ( cd "$TMP/check" && make -n design-check 2>&1 | head -3 )
  rm -rf "$TMP"
  echo "---"
done
```
Expected: dry-run prints without syntax errors.

- [ ] **Step 4: Commit**

```bash
cd /Users/dong.kyh/works/system-designs
git add _templates/node/Makefile _templates/python/Makefile
git commit -m "feat(templates): extend design-check to assert worksheets + ADRs

design-check now also requires:
- docs/requirements.md, docs/capacity-estimation.md, docs/failure-modes.md
  all exist and no longer contain template placeholder text
- docs/adr/ contains at least one real ADR (0000-template.md alone
  doesn't count)

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Task 6: README §7 pointer + repo `AGENTS.md` update

**Files:**
- Modify: `_templates/node/README.md`
- Modify: `_templates/python/README.md`
- Modify: `/Users/dong.kyh/works/system-designs/AGENTS.md`

- [ ] **Step 1: Update §7 (How to run) in `_templates/node/README.md`**

Locate the existing §7 block:

```markdown
## 7. How to run

```bash
make up      # start app + dependencies
make test    # run tests
make logs    # tail app logs
make down    # stop and clean volumes
```

Local dev (without Docker):
```bash
make install
make dev
```
```

Add a new paragraph at the END of §7, just before §8:

```markdown
### Design artifacts

Before changing code, read:

- [`docs/requirements.md`](./docs/requirements.md) — functional + numeric NFRs
- [`docs/capacity-estimation.md`](./docs/capacity-estimation.md) — back-of-envelope load and storage
- [`docs/failure-modes.md`](./docs/failure-modes.md) — what breaks first and how it degrades
- [`docs/adr/`](./docs/adr/) — Architecture Decision Records

Run `make design-check` to confirm the design artifacts are present
and non-trivial before declaring this project done.
```

- [ ] **Step 2: Apply the same change to `_templates/python/README.md`**

Same edit as Step 1. Stack-agnostic.

- [ ] **Step 3: Update repo-level `AGENTS.md`**

In `/Users/dong.kyh/works/system-designs/AGENTS.md`, locate the section about repo layout (the "Repo layout you need to know" bullet for `docs/learning/`). Update that bullet (if it exists) or add it if it isn't there yet:

```markdown
- `docs/learning/` — cross-cutting cheat sheets (latency numbers,
  consistency models, back-of-envelope methodology). Read once,
  reference often.
```

(Plan D's AGENTS.md already includes this bullet. If so, no change needed.)

Then, in the "The non-negotiable rule" section, ensure point 3 reads:

```markdown
3. ADRs (`docs/adr/`) for any non-obvious decision, plus the three
   worksheets (`docs/requirements.md`, `docs/capacity-estimation.md`,
   `docs/failure-modes.md`) filled with concrete values, not template
   text.
```

(Plan D's AGENTS.md mentioned ADRs already. Updating the wording so the worksheets are explicitly called out.)

- [ ] **Step 4: Commit**

```bash
cd /Users/dong.kyh/works/system-designs
git add _templates/node/README.md _templates/python/README.md AGENTS.md
git commit -m "docs: point README §7 and AGENTS.md to the new design worksheets

Each project README now has a 'Design artifacts' subsection listing the
worksheets and ADR dir, plus a 'make design-check' reminder. Repo
AGENTS.md updated so the non-negotiable rule explicitly mentions the
three worksheets, not just ADRs in general.

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Task 7: Repo `docs/learning/` cheat sheets

**Files:**
- Create: `docs/learning/README.md`
- Create: `docs/learning/latency-numbers.md`
- Create: `docs/learning/consistency-models.md`
- Create: `docs/learning/back-of-envelope.md`

- [ ] **Step 1: Create directory and `docs/learning/README.md`**

```bash
mkdir -p /Users/dong.kyh/works/system-designs/docs/learning
```

`docs/learning/README.md`:

```markdown
# Learning notes

Cross-cutting reference material. Read these once, then come back to
them every time you start a new project.

## Starter set

- [`latency-numbers.md`](./latency-numbers.md) — Jeff Dean's latency
  numbers, with the practical "what does this mean for my design?"
  layer added on top
- [`consistency-models.md`](./consistency-models.md) — strong /
  read-your-writes / monotonic / causal / eventual, with examples and
  when each matters
- [`back-of-envelope.md`](./back-of-envelope.md) — how to do capacity
  estimation in 5 minutes without being wildly wrong

## Deferred to a follow-up (F2)

- `cap-pacelc.md` — partition tolerance vs consistency vs latency
- `system-design-pattern-glossary.md` — saga, CQRS, event sourcing,
  sharding strategies, leader election, etc.
- `failure-modes-catalog.md` — common failure patterns across systems
- `tradeoff-cheatsheet.md` — "if you choose X, you give up Y"

(See the design spec for the full deferred list.)
```

- [ ] **Step 2: Create `docs/learning/latency-numbers.md`**

```markdown
# Latency numbers (every engineer should know)

Jeff Dean's "numbers you should know" — slightly updated. **Memorize
the order of magnitudes, not the exact digits.** The relative
differences are what drive design.

| Operation | Time | What this lets you do |
|---|---|---|
| L1 cache reference | ~1 ns | nothing — too small to think about |
| Branch mispredict | ~5 ns | tight loops add up |
| L2 cache reference | ~4 ns | structure data for cache locality |
| Mutex lock/unlock (contended) | ~25 ns | hot locks → contention |
| Main memory reference | ~100 ns | random access ≈ 1000× cache hit |
| Compress 1KB with snappy | ~3 µs | compression is "free" for network IO |
| Send 1KB over 1 Gbps network | ~10 µs | tiny vs disk |
| Read 4KB random from SSD | ~150 µs | SSDs are ~10–100× faster than HDDs |
| Read 1MB sequentially from memory | ~10 µs | streaming reads are very fast |
| Round-trip in same datacenter | ~500 µs | budget for *each* RPC hop |
| Read 1MB sequentially from SSD | ~1 ms | sequential SSD ≈ 1 GB/s |
| Disk seek (HDD) | ~10 ms | avoid HDDs for random IO |
| Read 1MB sequentially from HDD | ~30 ms | streaming HDDs ≈ 30 MB/s |
| Round-trip CA → Netherlands | ~150 ms | physics; no cache fixes this |

## Practical takeaways

- **A single internal RPC adds ~0.5 ms.** Ten serial hops adds ~5 ms.
  Fan out, don't chain.
- **A cache hit is ~10,000× faster than a cross-DC trip.** Cache anything
  whose value changes slower than it's read.
- **Random IO to SSD is fast (~150 µs) but not free** — at 1k IOPS per
  device, expensive workloads need NVMe or many devices.
- **A 1 GB working set fits in RAM today.** Don't reach for distributed
  databases prematurely; one big machine is often enough.
- **Compression is cheap, decompression is cheaper.** When in doubt,
  compress over the wire.
- **Physical distance matters more than software.** A multi-region
  design that requires cross-region writes on the hot path is rarely
  what you want.

## Approximations to keep handy

- 1 µs (microsecond) = 1,000 ns
- 1 ms (millisecond) = 1,000 µs = 1,000,000 ns
- 1 day = 86,400 s ≈ 100k s for rough estimates
- 1 year ≈ π × 10⁷ s ≈ 31.5M s
- "Three nines" (99.9%) ≈ 8.77 hours/year of downtime; 43.83 min/month
- "Four nines" (99.99%) ≈ 52.6 min/year
```

- [ ] **Step 3: Create `docs/learning/consistency-models.md`**

```markdown
# Consistency models

Picking the wrong consistency model is the #1 source of "works on
the demo, breaks in production" bugs. **Decide explicitly per
operation**, not per system.

## Linearizable (strong, externally consistent)

Every read returns the most recent write across all replicas. Looks
like a single machine running operations one at a time.

- **When you need it:** bank balances, primary-key uniqueness,
  leader election, distributed locks.
- **Cost:** every write coordinates with at least a quorum. Latency
  scales with the slowest replica in the quorum. Limited to within
  one consensus group (Raft / Paxos).
- **In practice:** Spanner (with TrueTime), CockroachDB, etcd, ZooKeeper.

## Sequential consistency

All operations appear in *some* total order, and the order respects
the program order of each client. Weaker than linearizable (no
real-time guarantee).

- **When you need it:** rare in distributed systems; common as a
  building block (single-shard databases provide this).

## Read-your-writes / session consistency

A client always sees its own writes. Other clients may see stale data.

- **When you need it:** anywhere a user expects "I just submitted that,
  why isn't it showing up?" — profile edits, cart updates, posting
  a comment.
- **How to get it:** route a session's reads to the same replica as
  its writes, OR include the write's version in subsequent reads.

## Monotonic reads

Once a client has seen a version, it never sees an older one. Doesn't
require seeing the latest; just no going backward.

- **When you need it:** UI that shows progress (count goes 5, 6, 5 is
  jarring); event logs.
- **How to get it:** sticky reads to one replica per client.

## Causal consistency

Operations causally related are seen in the same order by all
clients; operations that are concurrent can be seen in different
orders.

- **When you need it:** comments under a post (the comment must come
  after the post for everyone), chat threads.
- **How to get it:** vector clocks or version vectors.

## Eventual consistency

Replicas eventually converge. No guarantees on order or timing.

- **When you need it:** caches, DNS, analytics counters, social media
  like counts.
- **Watch out for:** lost updates ("last write wins" can erase work);
  use CRDTs if you need merge semantics.

## How to choose

Walk each operation through these questions:

1. **Could two concurrent operations conflict in a way that matters?**
   (If yes, you need at least strong consistency on the conflict path.)
2. **Will the user notice if they don't see their own write
   immediately?** (If yes, read-your-writes.)
3. **Will the UI flicker / go backward if updates arrive out of order?**
   (If yes, monotonic reads.)
4. **Are there causal relationships you must preserve?** (If yes,
   causal.)
5. **Otherwise, eventual is cheapest** — and that's a feature.

Decide per operation, document the choice in `docs/adr/`.

## A useful mental model

> Strong consistency is expensive at the data layer but cheap at the
> application layer (no bugs). Eventual is cheap at the data layer
> but expensive at the application layer (lots of edge cases).
> Choose accordingly per operation, not per system.
```

- [ ] **Step 4: Create `docs/learning/back-of-envelope.md`**

```markdown
# Back-of-envelope estimation

The goal is to be **roughly right** — within 1 order of magnitude.
Not to be precisely right.

## Approach in 5 minutes

1. **Estimate top of funnel.** Daily active users, sessions per DAU,
   requests per session. Pick conservative numbers; multiply.
2. **Convert to RPS.** Divide daily requests by 86,400 (the seconds
   in a day). Round to a power of 10.
3. **Spike-adjust.** Realistic peak is 2–5× the average. Use 3× as
   a default unless you know the workload.
4. **Read vs write split.** Most apps are 100:1 read-heavy. Specify
   if yours isn't.
5. **Size each item.** Bytes per record, records per user, total
   records.
6. **Multiply for storage.** records × bytes × replication factor.
7. **Compare to one machine.** Modern boxes do 10k RPS for trivial
   work, 1k RPS for heavyweight work, with 1 TB SSD and 64 GB RAM.
   If you fit, you don't need distribution yet.

## Reference numbers

Use these unless you have project-specific measurements.

| Thing | Default |
|---|---|
| Bytes per JSON record (simple) | 1 KB |
| Bytes per text post / comment | 1 KB |
| Bytes per image (thumbnail) | 50 KB |
| Bytes per image (full) | 500 KB – 5 MB |
| Bytes per minute of audio | 1 MB |
| Bytes per minute of video (SD) | 5 MB |
| Replication factor (one region) | 3× |
| Read amplification (indexes etc.) | 1.5–3× |
| Cache hit rate (well-tuned) | 90–99% |
| Read:write ratio (typical app) | 100:1 |
| Spike factor (avg → peak) | 3× |

## A worked example: URL shortener

- 100M users, 1 click/user/day → **1 GB/s? No** — clicks/day = 100M.
  RPS = 100M / 86,400 ≈ **1.2k RPS average, ~4k peak.** Trivial for
  one machine.
- 1M new short URLs/day. URL ≈ 100 bytes + indexes ≈ 250 bytes.
  Storage = 1M × 250 = 250 MB/day = **90 GB/year**. One node fits
  ~5 years.
- Reads = 100k:1 vs writes. Cache hit rate 99% → backend RPS = 12.
  Almost no backend load with a CDN/cache in front.

**Verdict:** does not need distributed storage. A single
load-balanced web tier + Postgres + Redis handles it.

## A worked example: news feed (Twitter-scale)

- 500M DAU, 50 reads/day per user → 25B reads/day → **290k RPS
  average, ~900k peak.** Needs serious distribution.
- Each timeline ≈ 500 tweets × ~300 bytes = 150 KB; fan-out write
  to ~200 followers on average for active users.
- Storage of *generated* timelines (fan-out-on-write):
  500M × 150 KB = 75 TB. Tractable on a sharded cache; hot.
- Storage of tweets: 500M users × 50 tweets/day × 300 bytes ≈
  **8 TB/day** = ~3 PB/year. Definitely sharded.

**Verdict:** distributed everything. Sharded write path, fan-out
service, cache tier, CDN for media.

## Common mistakes

- **Forgetting to account for indexes.** Multiply primary storage
  by 1.5–3× for indexes.
- **Using "average" peak.** Real peaks during news events / launches
  can be 10×+ the rolling average. Plan for sustainable handling at
  3× and graceful degradation at 10×.
- **Ignoring write amplification.** Append-only logs, materialized
  views, and downstream consumers can multiply write volume.
- **Designing for steady state when bursts dominate.** Cold starts
  and rebalances are when systems fail.
```

- [ ] **Step 5: Commit**

```bash
cd /Users/dong.kyh/works/system-designs
git add docs/learning/
git commit -m "docs(learning): add starter cheat sheets (latency, consistency, BoE)

Three cross-cutting references plus an index:
- latency-numbers.md: Jeff Dean's numbers + 'what this means for
  design' interpretation layer
- consistency-models.md: linearizable through eventual, with 'when
  each matters' and a decision flow
- back-of-envelope.md: 5-minute methodology + reference numbers +
  two worked examples (URL shortener and news feed)

README index lists what's here and what's deferred to F2.

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Task 8: Extend scaffold tests for the new template files

**Files:**
- Modify: `scripts/tests/test_new_project.sh`

- [ ] **Step 1: Extend the Node expected-files list**

Locate `test_scaffold_node_creates_expected_files`. The list currently ends with `docs/diagrams/.gitignore` (added in Plan E). Add the new files:

```bash
  for f in README.md Dockerfile docker-compose.yml Makefile package.json tsconfig.json \
           .eslintrc.json .prettierrc .env.example .gitignore .dockerignore \
           src/index.ts tests/smoke.test.ts \
           AGENTS.md DONE.md AGENT-PROMPT.md notes/gotchas.md \
           docs/diagrams/00-context.mmd docs/diagrams/01-sequence-happy-path.mmd docs/diagrams/.gitignore \
           docs/adr/0000-template.md docs/adr/README.md \
           docs/requirements.md docs/capacity-estimation.md docs/failure-modes.md; do
```

- [ ] **Step 2: Extend the Python expected-files list** with the same five new files:

```bash
  for f in README.md Dockerfile docker-compose.yml Makefile pyproject.toml \
           .env.example .gitignore .dockerignore \
           src/__init__.py src/main.py tests/__init__.py tests/test_smoke.py \
           AGENTS.md DONE.md AGENT-PROMPT.md notes/gotchas.md \
           docs/diagrams/00-context.mmd docs/diagrams/01-sequence-happy-path.mmd docs/diagrams/.gitignore \
           docs/adr/0000-template.md docs/adr/README.md \
           docs/requirements.md docs/capacity-estimation.md docs/failure-modes.md; do
```

- [ ] **Step 3: Add a substitution test for the new docs**

Append to the bottom of `/Users/dong.kyh/works/system-designs/scripts/tests/test_new_project.sh`:

```bash

# ---------- learning-aid template files: substitution coverage ----------

test_scaffold_substitutes_in_learning_docs() {
  local box; box=$(setup_sandbox)
  ( cd "$box" && ./scripts/new-project.sh apps learn-check python >/dev/null )
  local proj="$box/apps/learn-check"
  for f in docs/requirements.md docs/capacity-estimation.md docs/failure-modes.md \
           docs/adr/README.md docs/adr/0000-template.md; do
    [ -f "$proj/$f" ] || { echo "missing $f"; teardown_sandbox "$box"; return 1; }
  done
  # requirements.md and capacity-estimation.md include __PROJECT_TITLE__ in the heading.
  grep -q 'Learn Check' "$proj/docs/requirements.md" || { echo "title not substituted in requirements"; teardown_sandbox "$box"; return 1; }
  grep -q 'Learn Check' "$proj/docs/capacity-estimation.md" || { echo "title not substituted in capacity-estimation"; teardown_sandbox "$box"; return 1; }
  grep -q 'Learn Check' "$proj/docs/failure-modes.md" || { echo "title not substituted in failure-modes"; teardown_sandbox "$box"; return 1; }
  grep -q 'Learn Check' "$proj/docs/adr/README.md" || { echo "title not substituted in adr/README"; teardown_sandbox "$box"; return 1; }
  # Ensure no leftover placeholders in the new docs.
  if grep -r '__PROJECT_NAME__\|__CATEGORY__\|__PROJECT_TITLE__' "$proj/docs/" >/dev/null 2>&1; then
    echo "unsubstituted placeholders in docs/"
    grep -rn '__' "$proj/docs/" | head
    teardown_sandbox "$box"
    return 1
  fi
  teardown_sandbox "$box"
}
```

- [ ] **Step 4: Run the test suite — expect PASS**

```bash
/Users/dong.kyh/works/system-designs/scripts/tests/run-tests.sh 2>&1 | tail -10
```
Expected: all PASS. Total count grows by 1 new test (~57 → 58, exact count depends on Plan E's final count).

- [ ] **Step 5: Commit**

```bash
cd /Users/dong.kyh/works/system-designs
git add scripts/tests/test_new_project.sh
git commit -m "test(scripts): cover ADR + requirements + capacity + failure-modes templates

Extends scaffold expected-files lists and adds a substitution-coverage
test asserting __PROJECT_TITLE__ propagates into all four new docs
(requirements, capacity-estimation, failure-modes, adr/README) and no
placeholders remain.

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Task 9: Extend `test_design_check.sh` to cover the new gates

**Files:**
- Modify: `scripts/tests/test_design_check.sh`

- [ ] **Step 1: Update `test_design_check_passes_when_diagrams_rendered_and_readme_filled`**

The test currently passes if diagrams render and README placeholders are replaced. But the gate now ALSO requires:
- The 3 worksheets have their placeholder strings replaced (otherwise the "still contains template text" check fails)
- At least one real ADR file exists in `docs/adr/` (not just `0000-template.md`)

Locate the test in `/Users/dong.kyh/works/system-designs/scripts/tests/test_design_check.sh`. Replace it with this version:

```bash
test_design_check_passes_when_diagrams_rendered_and_readme_filled() {
  if ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; then
    echo "SKIP: docker not available (can't render diagrams)"
    return 0
  fi

  local box; box=$(_setup_design_sandbox)
  ( cd "$box" && ./scripts/new-project.sh apps design-pass-check node >/dev/null )
  local proj="$box/apps/design-pass-check"

  ( cd "$proj" && make diagram >/dev/null 2>&1 ) || {
    echo "make diagram failed"
    rm -rf "$box"
    return 1
  }

  # Replace placeholder copy in the README and the three worksheets so the
  # gate's "still contains template placeholder" checks pass.
  python3 - <<PY
import pathlib
def sub(path, replacements):
    p = pathlib.Path(path)
    t = p.read_text()
    for k, v in replacements.items():
        t = t.replace(k, v)
    p.write_text(t)

sub("$proj/README.md", {
    "_What are we building and why?_": "We are building a thing because reasons.",
    "_List the things this system must do_": "Serve 1k QPS at p99 < 50ms.",
})
sub("$proj/docs/requirements.md", {
    "_Capability 1_": "Accept POST /things with a JSON body.",
})
sub("$proj/docs/capacity-estimation.md", {
    "_primary entity_": "thing",
})
sub("$proj/docs/failure-modes.md", {
    "_Datastore unreachable_": "Database unreachable",
})
PY

  # Add one real ADR.
  cat > "$proj/docs/adr/0001-pick-postgres.md" <<'ADR'
# ADR-0001: Use Postgres for the primary store
**Status:** Accepted
## Context
We need a primary store with strong consistency on writes.
## Decision
Postgres 16 with logical replication.
## Consequences
- Battle-tested
- Operationally familiar
ADR

  ( cd "$proj" && make design-check >/dev/null 2>&1 )
  local rc=$?
  rm -rf "$box"
  [ $rc -eq 0 ]
}
```

(Just the one function body changes; everything else in the file stays the same.)

- [ ] **Step 2: Add a new negative test that asserts design-check fails when only some worksheets are filled**

Append to the bottom of `scripts/tests/test_design_check.sh`:

```bash

test_design_check_fails_when_worksheets_still_placeholder() {
  if ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; then
    echo "SKIP: docker not available"
    return 0
  fi
  local box; box=$(_setup_design_sandbox)
  ( cd "$box" && ./scripts/new-project.sh apps ws-fail-check node >/dev/null )
  local proj="$box/apps/ws-fail-check"

  ( cd "$proj" && make diagram >/dev/null 2>&1 ) || {
    echo "make diagram failed"; rm -rf "$box"; return 1
  }
  # Fill README only; leave worksheets and ADR untouched.
  python3 - <<PY
import pathlib
p = pathlib.Path("$proj/README.md")
t = p.read_text()
t = t.replace("_What are we building and why?_", "x").replace("_List the things this system must do_", "y")
p.write_text(t)
PY

  set +e
  ( cd "$proj" && make design-check >/dev/null 2>&1 )
  local rc=$?
  set -e
  rm -rf "$box"
  [ $rc -ne 0 ]
}

test_design_check_fails_when_only_adr_template_present() {
  if ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; then
    echo "SKIP: docker not available"
    return 0
  fi
  local box; box=$(_setup_design_sandbox)
  ( cd "$box" && ./scripts/new-project.sh apps adr-fail-check node >/dev/null )
  local proj="$box/apps/adr-fail-check"

  ( cd "$proj" && make diagram >/dev/null 2>&1 ) || {
    echo "make diagram failed"; rm -rf "$box"; return 1
  }

  python3 - <<PY
import pathlib
def sub(path, k, v):
    p = pathlib.Path(path); t = p.read_text(); p.write_text(t.replace(k, v))
sub("$proj/README.md", "_What are we building and why?_", "x")
sub("$proj/README.md", "_List the things this system must do_", "y")
sub("$proj/docs/requirements.md", "_Capability 1_", "x")
sub("$proj/docs/capacity-estimation.md", "_primary entity_", "x")
sub("$proj/docs/failure-modes.md", "_Datastore unreachable_", "x")
PY

  # Don't add any ADR — design-check should still fail.
  set +e
  ( cd "$proj" && make design-check >/dev/null 2>&1 )
  local rc=$?
  set -e
  rm -rf "$box"
  [ $rc -ne 0 ]
}
```

- [ ] **Step 3: Run all design-check tests — expect all PASS**

```bash
/Users/dong.kyh/works/system-designs/scripts/tests/run-tests.sh 2>&1 | grep -E "^Results:|test_design_check"
```
Expected: 4 design-check tests, all PASS (the two new negative tests + the existing fail-on-fresh-scaffold + the updated pass test).

- [ ] **Step 4: Commit**

```bash
cd /Users/dong.kyh/works/system-designs
git add scripts/tests/test_design_check.sh
git commit -m "test(design-check): extend coverage to worksheets + real ADR requirement

- Updated 'passes when everything is filled' test to also fill the
  three worksheets and add one real ADR
- Added 'fails when only README is filled (worksheets untouched)' test
- Added 'fails when only 0000-template.md is in docs/adr/' test

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Task 10: End-to-end verification

**Files:** none

- [ ] **Step 1: Full test suite**

```bash
/Users/dong.kyh/works/system-designs/scripts/tests/run-tests.sh 2>&1 | tail -10
```
Expected: all PASS.

- [ ] **Step 2: End-to-end demo: scaffold → render → fill → design-check**

```bash
SANDBOX=$(mktemp -d)
mkdir -p "$SANDBOX/scripts"
cp -R /Users/dong.kyh/works/system-designs/_templates "$SANDBOX/_templates"
cp /Users/dong.kyh/works/system-designs/scripts/new-project.sh "$SANDBOX/scripts/new-project.sh"
chmod +x "$SANDBOX/scripts/new-project.sh"

cd "$SANDBOX"
./scripts/new-project.sh apps full-demo python >/dev/null
cd apps/full-demo

echo "=== files present ==="
find docs -type f | sort

echo "=== design-check fails on fresh scaffold ==="
make design-check 2>&1 | head -10 ; echo "rc=$?"

cd /
rm -rf "$SANDBOX"
```
Expected:
- `docs/` contains the new files (adr/, requirements.md, capacity-estimation.md, failure-modes.md)
- design-check fails with a list of missing/placeholder artifacts

- [ ] **Step 3: Visit the cheat sheets**

```bash
cd /Users/dong.kyh/works/system-designs
ls docs/learning/
wc -l docs/learning/*.md
```
Expected: `README.md`, `latency-numbers.md`, `consistency-models.md`, `back-of-envelope.md`, all non-trivial line counts.

- [ ] **Step 4: Repo state clean**

```bash
cd /Users/dong.kyh/works/system-designs
git status
```
Expected: clean.

- [ ] **Step 5: Tag the milestone**

```bash
cd /Users/dong.kyh/works/system-designs
git tag -a learning-aids-v1 -m "Learning aids: ADR + worksheets per project + docs/learning/ cheat sheets"
```

---

## Done

After Task 10:
- Every new project has `docs/adr/`, `docs/requirements.md`, `docs/capacity-estimation.md`, `docs/failure-modes.md`
- `make design-check` enforces all of them are present + non-placeholder + at least one real ADR exists
- Repo `docs/learning/` has 3 cross-cutting cheat sheets agents and humans reference from any project
- DONE.md checklist (from Plan D) and AGENTS.md "non-negotiable rule" now have live infrastructure backing every reference

Follow-up plan (F2) — defer until you've used this on 2-3 real projects and know what's missing:
- `docs/learning/cap-pacelc.md`, `system-design-pattern-glossary.md`
- `docs/problems/` index with hints linking to recipes/services
- `_recipes/compose/k6-runner.yml` + per-project `tests/load.js`
- `make finalize` automation + postmortem template
