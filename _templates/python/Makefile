.PHONY: up down test lint logs shell install dev clean

install:
	uv sync

dev:
	uv run python -m src.main

up:
	docker compose up --build -d

down:
	docker compose down -v

test:
	uv run pytest -q

lint:
	uv run ruff check . && uv run ruff format --check .

logs:
	docker compose logs -f app

shell:
	docker compose exec app sh

clean:
	rm -rf .venv .pytest_cache .ruff_cache __pycache__ */__pycache__ */*/__pycache__
