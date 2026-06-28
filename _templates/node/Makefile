.PHONY: up down build test lint logs shell install dev clean diagram design-check

install:
	pnpm install

dev:
	pnpm dev

up:
	docker compose up --build -d

down:
	docker compose down -v

build:
	pnpm build

test:
	pnpm test

lint:
	pnpm lint

logs:
	docker compose logs -f app

shell:
	docker compose exec app sh

clean:
	rm -rf node_modules dist coverage

# --- diagram rendering ---
# Renders every docs/diagrams/*.mmd to *.svg using the official
# Mermaid CLI Docker image. Zero local install required.
MERMAID_IMAGE := minlag/mermaid-cli:11.4.2

diagram:
	@if ! command -v docker >/dev/null 2>&1; then \
	  echo "error: docker required for 'make diagram'" >&2; \
	  echo "       install Docker Desktop or OrbStack, then retry" >&2; \
	  exit 1; \
	fi
	@count=$$(ls docs/diagrams/*.mmd 2>/dev/null | wc -l | tr -d ' '); \
	if [ "$$count" = "0" ]; then echo "no diagrams under docs/diagrams/*.mmd"; exit 0; fi
	@for src in docs/diagrams/*.mmd; do \
	  out="$${src%.mmd}.svg"; \
	  echo "render $$src -> $$out"; \
	  docker run --rm -u $$(id -u):$$(id -g) \
	    -v "$$PWD":/data $(MERMAID_IMAGE) \
	    -i "/data/$$src" -o "/data/$$out" >/dev/null || exit 1; \
	done

# --- design completeness gate ---
# Asserts the project's design artifacts are present and non-trivial
# before declaring it ready for review/merge/finalize.
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
	if [ $$fail -eq 0 ]; then echo "design-check: OK"; else exit 1; fi
