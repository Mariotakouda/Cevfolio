# CEVFOLIO

Plateforme SaaS de CV et portfolios professionnels assistée par IA. Monorepo : backend et frontend dans le même dépôt.

```
Cevfolio/
├── backend/            Laravel (API REST, Sanctum, files d'attente)
├── frontend/           React + TypeScript + Vite + Tailwind
├── docs/               Cahier des charges, répartition du travail, openapi.yaml (à créer)
├── scripts/            configure.sh
├── docker-compose.yml  MySQL 8, Redis, MinIO (S3 local), Mailpit
└── Makefile            Raccourcis
```

## Prérequis
PHP 8.3+, Composer, Node 20+, Docker. Sous Windows : WSL ou Git Bash.

## Première installation
```bash
make setup
```
Démarre l'infrastructure, installe Sanctum, Redis, S3 et Larastan, configure `backend/.env`, recrée la base (`migrate:fresh`) et installe les dépendances du frontend.

## Lancer le projet (3 terminaux)
| Commande | Rôle | URL |
|---|---|---|
| `make backend` | API Laravel | http://localhost:8000 |
| `make queue` | Worker (IA, PDF) | |
| `make frontend` | Application React | http://localhost:5173 |

Console MinIO : http://localhost:9001 (`minioadmin` / `minioadmin`) · E-mails : http://localhost:8025

La page d'accueil du frontend affiche « API Laravel : connectée » quand tout communique.

## Règles
- Ne jamais committer `backend/.env`, `backend/vendor`, `frontend/node_modules`.
- Branches `feature/{ID}-{description}`, relecture croisée sous 24 h.
- L'API est décrite dans `docs/openapi.yaml` avant d'être codée.
