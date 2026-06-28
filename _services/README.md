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
