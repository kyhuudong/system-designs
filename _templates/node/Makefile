.PHONY: up down build test lint logs shell install dev clean

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
	pnpm test --run

lint:
	pnpm lint

logs:
	docker compose logs -f app

shell:
	docker compose exec app sh

clean:
	rm -rf node_modules dist coverage
