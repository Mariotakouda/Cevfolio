.PHONY: setup up down logs backend queue frontend test

setup:      
	bash scripts/setup.sh

up:         ## Démarre MySQL, Redis, MinIO, Mailpit
	docker compose up -d

down:       ## Arrête l'infrastructure
	docker compose down

logs:
	docker compose logs -f

backend:    ## Serveur Laravel (http://localhost:8000)
	cd backend && php artisan serve

queue:      ## Worker de file d'attente (IA, PDF)
	cd backend && php artisan queue:work

frontend:   ## Serveur React (http://localhost:5173)
	cd frontend && npm run dev

test:
	cd backend && php artisan test
	cd frontend && npm run build
