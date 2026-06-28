# Compose recipes

Drop-in `docker-compose` snippets you copy into a project's `docker-compose.yml`.

Each file starts with a comment header explaining what it provides and how to
merge it (the snippet uses YAML anchors and a `services:` block — you append
the services to your file, do not include the whole file as-is unless the
project's compose is empty).

## Available

- `postgres-with-adminer.yml` — Postgres 16 + Adminer web UI on :8080
- `kafka-kraft.yml` — single-broker Kafka 3.7 in KRaft mode (no Zookeeper)
