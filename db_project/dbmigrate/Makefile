.PHONY: help build up down restart logs clean test db-shell backend-shell frontend-shell apache-test

help:
	@echo "Log App - Docker Commands"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  build       - Build all Docker images"
	@echo "  up          - Start all services"
	@echo "  down        - Stop all services"
	@echo "  restart     - Restart all services"
	@echo "  logs        - View logs from all services"
	@echo "  logs-f      - Follow logs from all services"
	@echo "  clean       - Remove all containers, volumes, and images"
	@echo "  test        - Test API endpoints"
	@echo "  db-shell    - Open MariaDB shell"
	@echo "  backend-shell   - Open backend container shell"
	@echo "  frontend-shell  - Open frontend container shell"
	@echo "  ps          - Show running containers"
	@echo "  rebuild     - Rebuild and restart all services"
	@echo "  apache-test - Test Apache configuration"
	@echo ""

build:
	docker compose build

up:
	docker compose up -d
	@echo ""
	@echo "✅ Services started!"
	@echo "Frontend: http://localhost:3000"
	@echo "Backend:  http://localhost:5000"
	@echo ""

down:
	docker compose down

restart:
	docker compose restart

logs:
	docker compose logs

logs-f:
	docker compose logs -f

ps:
	docker compose ps

clean:
	docker compose down -v
	docker system prune -f

test:
	@echo "Testing API health..."
	@curl -s http://localhost:5000/api/health | grep -q "ok" && echo "✅ Backend is healthy" || echo "❌ Backend is not responding"
	@echo ""
	@echo "Testing frontend..."
	@curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 | grep -q "200" && echo "✅ Frontend is accessible" || echo "❌ Frontend is not responding"

db-shell:
	docker compose exec mariadb mysql -u logapp -plogapp123 logdb

backend-shell:
	docker compose exec backend sh

frontend-shell:
	docker compose exec frontend sh

rebuild:
	docker compose down
	docker compose build --no-cache
	docker compose up -d
	@echo ""
	@echo "✅ Services rebuilt and started!"
	@echo "Frontend: http://localhost:3000"
	@echo "Backend:  http://localhost:5000"

apache-test:
	@echo "Testing Apache configuration..."
	docker compose exec frontend httpd -t
	@echo ""
	@echo "Loaded Apache modules:"
	docker compose exec frontend httpd -M | grep rewrite
