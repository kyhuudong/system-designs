# Shared Side Services & Top-Level Makefile (Plan A) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a one-command sandbox of cloud emulators and dev infrastructure shared across all projects in the repo, brought up via top-level `make services-*` commands.

**Architecture:** A single `_services/docker-compose.yml` defines seven optional services on fixed ports (LocalStack, GCloud Pub/Sub, GCloud Firestore, Azurite, MinIO, Mailhog, Jaeger). A new top-level `Makefile` provides convenience targets. State persists under `_services/data/` (gitignored); `make services-reset` wipes it. Projects opt in by setting env vars; nothing in the per-project scaffold changes.

**Tech Stack:** Docker Compose, GNU make, bash. No new runtime languages.

**Spec:** [`docs/superpowers/specs/2026-06-28-shared-services-and-recipes-design.md`](../specs/2026-06-28-shared-services-and-recipes-design.md)

**Out of scope for this plan (Plan B will add):** `_recipes/` library, `make recipes-test` target.

---

## File Map

**Create:**
- `Makefile` — top-level convenience targets
- `_services/docker-compose.yml` — defines all sandbox services
- `_services/README.md` — endpoints, env conventions, per-service client examples
- `_services/data/.gitkeep` — placeholder so the directory exists in fresh clones
- `scripts/tests/test_top_makefile.sh` — verifies Makefile targets exist and `make help` lists them
- `scripts/tests/test_services_compose.sh` — verifies `docker compose config` validates the services file

**Modify:**
- `.gitignore` — ignore `_services/data/*` except `.gitkeep`
- `README.md` — add a "Side services" section linking to `_services/README.md`

---

## Task 1: Repo-level updates (`.gitignore`, root `README.md`)

**Files:**
- Modify: `/Users/dong.kyh/works/system-designs/.gitignore`
- Modify: `/Users/dong.kyh/works/system-designs/README.md`
- Create: `/Users/dong.kyh/works/system-designs/_services/data/.gitkeep`

- [ ] **Step 1: Create the empty `_services/data/` directory with a `.gitkeep`**

```bash
mkdir -p /Users/dong.kyh/works/system-designs/_services/data
: > /Users/dong.kyh/works/system-designs/_services/data/.gitkeep
```

- [ ] **Step 2: Add `_services/data/` exception to `.gitignore`**

Append the following to the END of `/Users/dong.kyh/works/system-designs/.gitignore` (do NOT replace existing content):

```gitignore

# Shared side services persistent state (kept out of git; .gitkeep preserved)
_services/data/*
!_services/data/.gitkeep
```

- [ ] **Step 3: Update root `README.md` — add a "Side services" section**

Insert a new section ABOVE the existing `## Catalog` section in `/Users/dong.kyh/works/system-designs/README.md`. The section content:

```markdown
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

```

- [ ] **Step 4: Verify the directory structure and gitignore**

```bash
cd /Users/dong.kyh/works/system-designs
ls -la _services/data
git check-ignore -v _services/data/junk.txt    # should match the ignore rule
git check-ignore -v _services/data/.gitkeep    # should print nothing (NOT ignored)
echo "exit=$?"
```
Expected:
- `_services/data/.gitkeep` exists
- `junk.txt` is ignored (`git check-ignore` exits 0 and prints the matching rule)
- `.gitkeep` is NOT ignored (`git check-ignore` exits 1 and prints nothing)

- [ ] **Step 5: Commit**

```bash
cd /Users/dong.kyh/works/system-designs
git add .gitignore README.md _services/data/.gitkeep
git commit -m "chore: scaffold _services/data with gitignore exception and README pointer

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Task 2: Top-level `Makefile` with smoke test

We TDD the Makefile by writing a smoke test that checks for the existence of every documented target and that `make help` lists them.

**Files:**
- Create: `/Users/dong.kyh/works/system-designs/scripts/tests/test_top_makefile.sh`
- Create: `/Users/dong.kyh/works/system-designs/Makefile`

- [ ] **Step 1: Write the smoke test (will fail until Makefile exists)**

Create `/Users/dong.kyh/works/system-designs/scripts/tests/test_top_makefile.sh`:

```bash
#!/usr/bin/env bash
# Tests for the top-level Makefile.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MAKEFILE="$REPO_ROOT/Makefile"

# Every target the spec promises.
EXPECTED_TARGETS=(
  services-up
  services-down
  services-logs
  services-status
  services-reset
  services-reset-force
  help
)

test_top_makefile_exists() {
  [ -f "$MAKEFILE" ]
}

test_top_makefile_defines_every_target() {
  local missing=0
  for t in "${EXPECTED_TARGETS[@]}"; do
    # Match a line of the form "target:" possibly followed by deps, but
    # not lines like "target_long:" — anchor on word boundary.
    if ! grep -qE "^${t}[[:space:]]*:" "$MAKEFILE"; then
      echo "missing target: $t"
      missing=$((missing + 1))
    fi
  done
  [ $missing -eq 0 ]
}

test_top_makefile_help_lists_every_target() {
  local out
  out=$(cd "$REPO_ROOT" && make help 2>&1)
  for t in "${EXPECTED_TARGETS[@]}"; do
    if ! echo "$out" | grep -qE "^[[:space:]]*${t}\b"; then
      echo "make help did not list: $t"
      echo "--- make help output ---"
      echo "$out"
      return 1
    fi
  done
}

test_top_makefile_default_target_is_help() {
  # Running bare `make` should print the help text.
  local out
  out=$(cd "$REPO_ROOT" && make 2>&1)
  echo "$out" | grep -qE "^Usage:|^Targets:|services-up"
}

test_top_makefile_reset_requires_confirmation() {
  # Pipe an empty response — should refuse and exit non-zero.
  set +e
  ( cd "$REPO_ROOT" && printf '\n' | make services-reset >/dev/null 2>&1 )
  local rc=$?
  set -e
  [ $rc -ne 0 ]
}
```

- [ ] **Step 2: Run the test — expect all to fail (no Makefile yet)**

```bash
/Users/dong.kyh/works/system-designs/scripts/tests/run-tests.sh 2>&1 | grep -E "^Results:|^  test_top_makefile"
```
Expected: 5 `test_top_makefile_*` lines all `FAIL`. (Existing 19 scaffolding tests still PASS.)

- [ ] **Step 3: Create `/Users/dong.kyh/works/system-designs/Makefile`**

```makefile
# Top-level Makefile for the system-designs repo.
# Convenience targets for the shared side services in _services/.
# Per-project commands live in each project's own Makefile.

SHELL := /usr/bin/env bash
COMPOSE := docker compose -f _services/docker-compose.yml

.PHONY: help services-up services-down services-logs services-status services-reset services-reset-force

# Bare `make` prints help.
.DEFAULT_GOAL := help

help: ## Show this help
	@echo "Usage: make <target>"
	@echo ""
	@echo "Targets:"
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z0-9_-]+:.*##/ {printf "  %-22s %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "Tip: target individual services directly, e.g.:"
	@echo "  $(COMPOSE) up -d localstack mailhog"

services-up: ## Start all shared side services in the background
	$(COMPOSE) up -d

services-down: ## Stop all shared side services (volumes preserved)
	$(COMPOSE) down

services-logs: ## Tail logs from all shared side services
	$(COMPOSE) logs -f

services-status: ## Show docker compose status of shared side services
	$(COMPOSE) ps

services-reset: ## Stop services and WIPE _services/data/ (prompts for confirmation)
	@read -r -p "This will wipe _services/data/. Are you sure? [y/N] " ans; \
	  if [ "$$ans" != "y" ] && [ "$$ans" != "Y" ]; then \
	    echo "Aborted."; exit 1; \
	  fi
	$(COMPOSE) down -v
	@echo "Done. _services/data/ wiped."

services-reset-force: ## Same as services-reset but skips the confirmation prompt
	$(COMPOSE) down -v
	@echo "Done. _services/data/ wiped."
```

- [ ] **Step 4: Run the test — expect all 5 to PASS**

```bash
/Users/dong.kyh/works/system-designs/scripts/tests/run-tests.sh 2>&1 | grep -E "^Results:|^  test_top_makefile"
```

Expected: all 5 `test_top_makefile_*` tests PASS. The reset-confirmation test passes deterministically because the Makefile rule exits non-zero on empty input *before* reaching the docker compose line — Docker availability is irrelevant.

If any test FAILs, re-read the test output and fix the Makefile. Re-run until clean:

```bash
/Users/dong.kyh/works/system-designs/scripts/tests/run-tests.sh 2>&1 | tail -10
```

- [ ] **Step 5: Manually verify `make help` looks good**

```bash
cd /Users/dong.kyh/works/system-designs
make
```
Expected: prints `Usage: make <target>`, then a `Targets:` list showing each target with its `##` comment as description, then the tip about targeting individual services.

- [ ] **Step 6: Commit**

```bash
cd /Users/dong.kyh/works/system-designs
git add Makefile scripts/tests/test_top_makefile.sh
git commit -m "feat: add top-level Makefile with services-* targets (TDD)

Provides one-command lifecycle for the shared sandbox services:
services-up, services-down, services-logs, services-status,
services-reset (with confirmation), services-reset-force. 'make' and
'make help' print a documented target list parsed from ## comments.

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Task 3: `_services/docker-compose.yml` with all seven services + config smoke test

We TDD the compose file by adding a smoke test that runs `docker compose config --quiet` against it. If Docker isn't installed in the environment, the test should SKIP (exit 0 with a notice).

**Files:**
- Create: `/Users/dong.kyh/works/system-designs/scripts/tests/test_services_compose.sh`
- Create: `/Users/dong.kyh/works/system-designs/_services/docker-compose.yml`

- [ ] **Step 1: Write the smoke test**

Create `/Users/dong.kyh/works/system-designs/scripts/tests/test_services_compose.sh`:

```bash
#!/usr/bin/env bash
# Tests for _services/docker-compose.yml.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COMPOSE_FILE="$REPO_ROOT/_services/docker-compose.yml"

test_services_compose_exists() {
  [ -f "$COMPOSE_FILE" ]
}

test_services_compose_validates() {
  # Skip cleanly if docker compose isn't available (e.g., a CI image without docker).
  if ! command -v docker >/dev/null 2>&1; then
    echo "SKIP: docker not installed"
    return 0
  fi
  if ! docker compose version >/dev/null 2>&1; then
    echo "SKIP: 'docker compose' subcommand not available"
    return 0
  fi
  docker compose -f "$COMPOSE_FILE" config --quiet
}

test_services_compose_defines_all_seven_services() {
  local expected=(localstack gcloud-pubsub gcloud-firestore azurite minio mailhog jaeger)
  local missing=0
  for s in "${expected[@]}"; do
    # Match a service entry: 2-space-indented service name followed by colon, at column start.
    if ! grep -qE "^  ${s}:[[:space:]]*$" "$COMPOSE_FILE"; then
      echo "missing service: $s"
      missing=$((missing + 1))
    fi
  done
  [ $missing -eq 0 ]
}

test_services_compose_uses_named_network() {
  grep -qE "^[[:space:]]*system-designs-sandbox:[[:space:]]*$" "$COMPOSE_FILE"
}

test_services_compose_persists_state() {
  # Check that LocalStack / Azurite / MinIO / Firestore bind-mount under _services/data/.
  local expected_paths=(
    "./data/localstack"
    "./data/azurite"
    "./data/minio"
    "./data/gcloud-firestore"
  )
  local missing=0
  for p in "${expected_paths[@]}"; do
    if ! grep -q "$p" "$COMPOSE_FILE"; then
      echo "missing volume bind: $p"
      missing=$((missing + 1))
    fi
  done
  [ $missing -eq 0 ]
}
```

- [ ] **Step 2: Run the test — expect 5 fails (compose file missing)**

```bash
/Users/dong.kyh/works/system-designs/scripts/tests/run-tests.sh 2>&1 | grep -E "^Results:|^  test_services_compose"
```
Expected: all 5 `test_services_compose_*` tests FAIL.

- [ ] **Step 3: Create `/Users/dong.kyh/works/system-designs/_services/docker-compose.yml`**

```yaml
# Shared sandbox infrastructure for the system-designs repo.
# Brought up via top-level `make services-up`.
# Each service uses a fixed host port so projects can hard-code endpoints.
# Persistent state lives under ./data/<service>/ (gitignored).

networks:
  system-designs-sandbox:
    name: system-designs-sandbox
    driver: bridge

services:

  # ---- AWS API simulator (OSS LocalStack) ------------------------------
  localstack:
    image: localstack/localstack:3
    container_name: sds-localstack
    restart: unless-stopped
    ports:
      - "4566:4566"
    environment:
      DEBUG: "0"
      SERVICES: "s3,sqs,sns,dynamodb,kms,secretsmanager,events,iam,logs,lambda"
      PERSISTENCE: "1"
      AWS_DEFAULT_REGION: "us-east-1"
    volumes:
      - ./data/localstack:/var/lib/localstack
      - /var/run/docker.sock:/var/run/docker.sock
    networks:
      - system-designs-sandbox

  # ---- GCP Pub/Sub emulator --------------------------------------------
  gcloud-pubsub:
    image: gcr.io/google.com/cloudsdktool/google-cloud-cli:emulators
    container_name: sds-gcloud-pubsub
    restart: unless-stopped
    command: >
      gcloud beta emulators pubsub start
      --host-port=0.0.0.0:8085
      --project=local-dev
    ports:
      - "8085:8085"
    networks:
      - system-designs-sandbox

  # ---- GCP Firestore (Native mode) emulator ----------------------------
  gcloud-firestore:
    image: gcr.io/google.com/cloudsdktool/google-cloud-cli:emulators
    container_name: sds-gcloud-firestore
    restart: unless-stopped
    command: >
      gcloud beta emulators firestore start
      --host-port=0.0.0.0:8086
      --database-mode=firestore-native
    ports:
      - "8086:8086"
    volumes:
      - ./data/gcloud-firestore:/data
    networks:
      - system-designs-sandbox

  # ---- Azure Storage emulator (Blob / Queue / Table) -------------------
  azurite:
    image: mcr.microsoft.com/azure-storage/azurite:latest
    container_name: sds-azurite
    restart: unless-stopped
    command: >
      azurite --loose
      --blobHost 0.0.0.0
      --queueHost 0.0.0.0
      --tableHost 0.0.0.0
      --location /data
    ports:
      - "10000:10000"   # blob
      - "10001:10001"   # queue
      - "10002:10002"   # table
    volumes:
      - ./data/azurite:/data
    networks:
      - system-designs-sandbox

  # ---- S3-compatible object store --------------------------------------
  minio:
    image: minio/minio:latest
    container_name: sds-minio
    restart: unless-stopped
    command: server /data --console-address ":9001"
    environment:
      MINIO_ROOT_USER: "minioadmin"
      MINIO_ROOT_PASSWORD: "minioadmin"
    ports:
      - "9000:9000"     # API
      - "9001:9001"     # web console
    volumes:
      - ./data/minio:/data
    networks:
      - system-designs-sandbox

  # ---- Fake SMTP for testing email flows -------------------------------
  mailhog:
    image: mailhog/mailhog:latest
    container_name: sds-mailhog
    restart: unless-stopped
    ports:
      - "1025:1025"     # SMTP
      - "8025:8025"     # web UI
    networks:
      - system-designs-sandbox

  # ---- Distributed tracing (all-in-one) --------------------------------
  jaeger:
    image: jaegertracing/all-in-one:1.55
    container_name: sds-jaeger
    restart: unless-stopped
    environment:
      COLLECTOR_OTLP_ENABLED: "true"
    ports:
      - "16686:16686"   # web UI
      - "4317:4317"     # OTLP gRPC
      - "4318:4318"     # OTLP HTTP
    networks:
      - system-designs-sandbox
```

- [ ] **Step 4: Run the smoke tests — expect all 5 to PASS**

```bash
/Users/dong.kyh/works/system-designs/scripts/tests/run-tests.sh 2>&1 | grep -E "^Results:|^  test_services_compose"
```
Expected: all 5 `test_services_compose_*` tests PASS. If `test_services_compose_validates` shows SKIP-style PASS (Docker not available), that's still PASS — note it but continue.

- [ ] **Step 5: Manual validation when Docker is available**

```bash
cd /Users/dong.kyh/works/system-designs
docker compose -f _services/docker-compose.yml config --quiet && echo OK
docker compose -f _services/docker-compose.yml config --services
```
Expected: first command prints `OK`; second prints all 7 service names.

- [ ] **Step 6: Commit**

```bash
cd /Users/dong.kyh/works/system-designs
git add _services/docker-compose.yml scripts/tests/test_services_compose.sh
git commit -m "feat(_services): add shared sandbox compose (LocalStack, GCloud, Azurite, MinIO, Mailhog, Jaeger)

Seven sandbox services on fixed host ports, sharing the
system-designs-sandbox docker network. Storage-like services
(LocalStack, Azurite, MinIO, Firestore) persist under ./data/.
Validated by docker compose config + 5 smoke tests.

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Task 4: `_services/README.md` — endpoints, env conventions, client examples

This task is pure documentation. Write the README that tells users (a) what each service does, (b) what env vars to set in their project, (c) minimal Python and Node client examples, (d) how to admin / inspect / reset.

**Files:**
- Create: `/Users/dong.kyh/works/system-designs/_services/README.md`

- [ ] **Step 1: Create `/Users/dong.kyh/works/system-designs/_services/README.md`**

````markdown
# Side services (shared sandbox)

A one-command sandbox of cloud emulators and dev infrastructure. Every project in
this repo can connect to these services on fixed `localhost` ports — no need to
run your own LocalStack / MinIO / Pub/Sub emulator inside every project.

## Lifecycle

From the repo root:

```bash
make services-up         # start everything in the background
make services-status     # show what's running
make services-logs       # tail logs (Ctrl-C to stop tailing)
make services-down       # stop everything (volumes preserved)
make services-reset      # stop AND wipe _services/data/ (prompts)
make services-reset-force # same as reset but skips the prompt
```

Targeting a subset is easy — call docker compose directly:

```bash
docker compose -f _services/docker-compose.yml up -d localstack mailhog
docker compose -f _services/docker-compose.yml stop jaeger
```

**Approximate footprint with everything running:** ~2–3 GB RAM. Start only the
services you need if memory is tight.

## Connecting from a project

- **Project runs on the host** (via `make dev`): use `localhost:<port>`.
- **Project runs inside its own Docker compose:** use `host.docker.internal:<port>` on
  Mac/Windows; on Linux add the following to your project's app service:
  ```yaml
  extra_hosts:
    - "host.docker.internal:host-gateway"
  ```

Always read endpoints from env vars so the same code works against real cloud
later. Each service section below lists the env vars to set.

## Port map

| Port | Service | Notes |
|---|---|---|
| 4566 | LocalStack | AWS API edge port |
| 8085 | GCloud Pub/Sub emulator | |
| 8086 | GCloud Firestore emulator | |
| 9000 | MinIO | S3-compatible API |
| 9001 | MinIO | Web console |
| 10000 | Azurite | Blob |
| 10001 | Azurite | Queue |
| 10002 | Azurite | Table |
| 1025 | Mailhog | SMTP |
| 8025 | Mailhog | Web UI |
| 16686 | Jaeger | Web UI |
| 4317 | Jaeger | OTLP gRPC |
| 4318 | Jaeger | OTLP HTTP |

---

## LocalStack (AWS)

OSS edition. Enabled services: S3, SQS, SNS, DynamoDB, KMS, Secrets Manager,
EventBridge, IAM, CloudWatch Logs, Lambda (basic). Anything else needs LocalStack Pro.

**Env vars for your project:**
```bash
AWS_ENDPOINT_URL=http://localhost:4566
AWS_ACCESS_KEY_ID=test
AWS_SECRET_ACCESS_KEY=test
AWS_DEFAULT_REGION=us-east-1
```

**Python (boto3):**
```python
import os, boto3
s3 = boto3.client("s3", endpoint_url=os.environ["AWS_ENDPOINT_URL"])
s3.create_bucket(Bucket="my-bucket")
```

**Node (AWS SDK v3):**
```typescript
import { S3Client, CreateBucketCommand } from '@aws-sdk/client-s3';
const s3 = new S3Client({
  endpoint: process.env.AWS_ENDPOINT_URL,
  region: process.env.AWS_DEFAULT_REGION,
  forcePathStyle: true,
  credentials: { accessKeyId: 'test', secretAccessKey: 'test' },
});
await s3.send(new CreateBucketCommand({ Bucket: 'my-bucket' }));
```

**Admin / inspect:** `aws --endpoint-url=http://localhost:4566 s3 ls`

**Reset just this service:** `docker compose -f _services/docker-compose.yml rm -sfv localstack && sudo rm -rf _services/data/localstack`

---

## GCloud Pub/Sub emulator

Project ID is hard-coded to `local-dev`. Topics and subscriptions are ephemeral
(emulator is stateless across restarts unless you stop without removing).

**Env vars:**
```bash
PUBSUB_EMULATOR_HOST=localhost:8085
GOOGLE_CLOUD_PROJECT=local-dev
```

**Python (`google-cloud-pubsub`):**
```python
import os
from google.cloud import pubsub_v1
# PUBSUB_EMULATOR_HOST is picked up automatically.
publisher = pubsub_v1.PublisherClient()
topic = publisher.create_topic(name="projects/local-dev/topics/hello")
publisher.publish(topic.name, b"hi").result()
```

**Node (`@google-cloud/pubsub`):**
```typescript
import { PubSub } from '@google-cloud/pubsub';
// PUBSUB_EMULATOR_HOST is picked up automatically.
const pubsub = new PubSub({ projectId: process.env.GOOGLE_CLOUD_PROJECT });
const [topic] = await pubsub.createTopic('hello');
await topic.publishMessage({ data: Buffer.from('hi') });
```

---

## GCloud Firestore emulator (Native mode)

**Env vars:**
```bash
FIRESTORE_EMULATOR_HOST=localhost:8086
GOOGLE_CLOUD_PROJECT=local-dev
```

**Python (`google-cloud-firestore`):**
```python
from google.cloud import firestore
db = firestore.Client(project="local-dev")
db.collection("users").document("alice").set({"name": "Alice"})
```

**Node (`@google-cloud/firestore`):**
```typescript
import { Firestore } from '@google-cloud/firestore';
const db = new Firestore({ projectId: process.env.GOOGLE_CLOUD_PROJECT });
await db.collection('users').doc('alice').set({ name: 'Alice' });
```

---

## Azurite (Azure Storage)

Uses the well-known dev key. Connection string is fixed and safe to put in `.env`.

**Env vars:**
```bash
AZURE_STORAGE_CONNECTION_STRING="DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://localhost:10000/devstoreaccount1;QueueEndpoint=http://localhost:10001/devstoreaccount1;TableEndpoint=http://localhost:10002/devstoreaccount1;"
```

**Python (`azure-storage-blob`):**
```python
import os
from azure.storage.blob import BlobServiceClient
svc = BlobServiceClient.from_connection_string(os.environ["AZURE_STORAGE_CONNECTION_STRING"])
svc.create_container("photos")
```

**Node (`@azure/storage-blob`):**
```typescript
import { BlobServiceClient } from '@azure/storage-blob';
const svc = BlobServiceClient.fromConnectionString(process.env.AZURE_STORAGE_CONNECTION_STRING!);
await svc.createContainer('photos');
```

---

## MinIO (S3-compatible)

Root user / pass: `minioadmin` / `minioadmin` (dev only).

**Env vars:**
```bash
S3_ENDPOINT_URL=http://localhost:9000
S3_ACCESS_KEY=minioadmin
S3_SECRET_KEY=minioadmin
S3_REGION=us-east-1
```

**Python (boto3 against MinIO):**
```python
import os, boto3
s3 = boto3.client(
    "s3",
    endpoint_url=os.environ["S3_ENDPOINT_URL"],
    aws_access_key_id=os.environ["S3_ACCESS_KEY"],
    aws_secret_access_key=os.environ["S3_SECRET_KEY"],
    region_name=os.environ["S3_REGION"],
)
s3.create_bucket(Bucket="my-bucket")
```

**Web console:** http://localhost:9001 (login `minioadmin` / `minioadmin`).

---

## Mailhog (fake SMTP)

Catches all outbound mail; nothing is delivered for real.

**Env vars:**
```bash
SMTP_HOST=localhost
SMTP_PORT=1025
```

**Inspect captured mail:** http://localhost:8025

**Python (stdlib):**
```python
import os, smtplib
from email.mime.text import MIMEText
msg = MIMEText("hello")
msg["From"] = "app@example.com"
msg["To"] = "user@example.com"
msg["Subject"] = "test"
with smtplib.SMTP(os.environ["SMTP_HOST"], int(os.environ["SMTP_PORT"])) as s:
    s.send_message(msg)
```

**Node (`nodemailer`):**
```typescript
import nodemailer from 'nodemailer';
const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST,
  port: Number(process.env.SMTP_PORT),
  secure: false,
});
await transporter.sendMail({
  from: 'app@example.com', to: 'user@example.com', subject: 'test', text: 'hello',
});
```

---

## Jaeger (distributed tracing)

All-in-one Jaeger with OTLP receiver enabled.

**Env vars:**
```bash
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318      # HTTP
# OR
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317      # gRPC
```

**Inspect traces:** http://localhost:16686

**Python (OpenTelemetry SDK):**
```python
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter

trace.set_tracer_provider(TracerProvider())
trace.get_tracer_provider().add_span_processor(BatchSpanProcessor(OTLPSpanExporter()))
tracer = trace.get_tracer("my-service")
with tracer.start_as_current_span("hello"):
    pass
```

**Node (`@opentelemetry/sdk-node`):**
```typescript
import { NodeSDK } from '@opentelemetry/sdk-node';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';
const sdk = new NodeSDK({ traceExporter: new OTLPTraceExporter() });
sdk.start();
```
````

- [ ] **Step 2: Sanity-check the README renders**

```bash
cd /Users/dong.kyh/works/system-designs
# If a markdown renderer is available, inspect; otherwise just verify length.
wc -l _services/README.md
head -40 _services/README.md
```
Expected: ~250+ lines; the head should show the title, lifecycle commands, and the port map intro.

- [ ] **Step 3: Commit**

```bash
cd /Users/dong.kyh/works/system-designs
git add _services/README.md
git commit -m "docs(_services): document endpoints, env vars, and client examples for all 7 services

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Task 5: End-to-end verification

Final check that the moving parts actually work together. Skip the heavy "pull and start all images" e2e if Docker isn't available locally — the compose-config validation in Task 3 already covers correctness.

**Files:** none (verification only)

- [ ] **Step 1: Verify the full test suite passes**

```bash
/Users/dong.kyh/works/system-designs/scripts/tests/run-tests.sh 2>&1 | tail -15
```
Expected: all tests PASS (the existing 19 scaffolding tests PLUS the 5 Makefile tests PLUS the 5 services-compose tests = 29 total). If a test SKIPs because Docker isn't available, that still counts as PASS in this harness.

- [ ] **Step 2: Verify `make help` looks reasonable**

```bash
cd /Users/dong.kyh/works/system-designs
make
```
Expected: usage line, target list with descriptions, the tip line at the end. Every documented target is listed.

- [ ] **Step 3: Verify Docker compose config (if Docker is available)**

```bash
cd /Users/dong.kyh/works/system-designs
if command -v docker >/dev/null && docker compose version >/dev/null 2>&1; then
  docker compose -f _services/docker-compose.yml config --quiet && echo "compose config OK"
  docker compose -f _services/docker-compose.yml config --services
else
  echo "Docker not available — skipping live validation."
fi
```
Expected (if Docker available): `compose config OK` and the 7 service names printed. (If not available, just the skip notice — acceptable.)

- [ ] **Step 4 (optional, heavy): Bring everything up briefly**

Only run this if you have Docker, ~3 GB free RAM, and ~5 minutes for image pulls on first run:

```bash
cd /Users/dong.kyh/works/system-designs
make services-up
sleep 30
make services-status
# Quick reachability check
curl -sf http://localhost:4566/_localstack/health | head -c 200 || true
curl -sf http://localhost:8025/api/v2/messages | head -c 100 || true
curl -sf http://localhost:9001 -o /dev/null && echo "minio console reachable"
curl -sf http://localhost:16686 -o /dev/null && echo "jaeger UI reachable"
make services-down
```
Expected: status shows 7 containers `Up`; the curl probes succeed (HTTP 200 on the health/UI endpoints). Then `services-down` stops them cleanly. Volumes survive under `_services/data/`.

- [ ] **Step 5: Repo sanity check**

```bash
cd /Users/dong.kyh/works/system-designs
git status
ls
ls _services
```
Expected: working tree clean (or only the `_services/data/<service>/` directories from optional step 4, which are gitignored). Top level shows the new `Makefile` and `_services/`. `ls _services` shows `README.md`, `docker-compose.yml`, `data/`.

- [ ] **Step 6: Tag the milestone**

```bash
cd /Users/dong.kyh/works/system-designs
git tag -a side-services-v1 -m "Shared side services: top-level Makefile + _services/ sandbox compose"
```

---

## Done

After Task 5, any project in the repo can use shared cloud emulators without spinning up its own. The typical workflow becomes:

```bash
make services-up                                        # once per session
cd apps/url-shortener                                   # work on a project
echo "AWS_ENDPOINT_URL=http://localhost:4566" >> .env  # opt in to a side service
make up                                                 # start the project
```

When you're done practicing, `make services-down` (preserve state) or `make services-reset-force` (start fresh next time).

The next plan (Plan B, deferred) will add the `_recipes/` library and `make recipes-test`.
