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
