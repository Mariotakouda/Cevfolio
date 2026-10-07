#!/usr/bin/env bash
# Configure le projet Cevfolio EXISTANT (backend Laravel déjà créé) selon le cahier des charges.
# À lancer depuis la racine : bash scripts/configure.sh   (ou : make setup)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
need() { command -v "$1" >/dev/null 2>&1 || { echo "Erreur : '$1' est introuvable."; exit 1; }; }
need php; need composer; need node; need npm; need docker
[ -f backend/artisan ] || { echo "Erreur : backend/artisan introuvable. Lancez ce script depuis la racine du projet."; exit 1; }

echo "==> 1/5 Infrastructure Docker (MySQL, Redis, MinIO, Mailpit)"
docker compose up -d

echo "==> 2/5 Paquets backend"
cd backend
composer install --no-interaction
composer require laravel/sanctum predis/predis "league/flysystem-aws-s3-v3:^3.0" --no-interaction
composer require --dev larastan/larastan --no-interaction
php artisan vendor:publish --provider="Laravel\Sanctum\SanctumServiceProvider" --no-interaction

# Les identifiants des utilisateurs sont des ULID : la table des jetons doit suivre.
TOKENS_MIGRATION=$(ls database/migrations/*create_personal_access_tokens_table.php | head -1)
sed -i.bak "s/\$table->morphs('tokenable')/\$table->ulidMorphs('tokenable')/" "$TOKENS_MIGRATION" && rm -f "$TOKENS_MIGRATION.bak"
grep -q "ulidMorphs('tokenable')" "$TOKENS_MIGRATION" || echo "ATTENTION : remplacez \$table->morphs('tokenable') par \$table->ulidMorphs('tokenable') dans $TOKENS_MIGRATION"

echo "==> 3/5 Fichier .env"
[ -f .env ] || cp .env.example .env
set_env() { if grep -qE "^#?\s*$1=" .env; then sed -i.bak -E "s|^#?\s*$1=.*|$1=$2|" .env; else echo "$1=$2" >> .env; fi; }
set_env APP_NAME CEVFOLIO
set_env APP_URL http://localhost:8000
set_env FRONTEND_URL http://localhost:5173
set_env APP_LOCALE fr
set_env DB_CONNECTION mysql
set_env DB_HOST 127.0.0.1
set_env DB_PORT 3306
set_env DB_DATABASE cevfolio
set_env DB_USERNAME cevfolio
set_env DB_PASSWORD secret
set_env REDIS_CLIENT predis
set_env CACHE_STORE redis
set_env QUEUE_CONNECTION redis
set_env SESSION_DRIVER redis
set_env SESSION_DOMAIN localhost
set_env SANCTUM_STATEFUL_DOMAINS localhost:5173
set_env FILESYSTEM_DISK s3
set_env AWS_ACCESS_KEY_ID minioadmin
set_env AWS_SECRET_ACCESS_KEY minioadmin
set_env AWS_DEFAULT_REGION us-east-1
set_env AWS_BUCKET cevfolio
set_env AWS_ENDPOINT http://127.0.0.1:9000
set_env AWS_USE_PATH_STYLE_ENDPOINT true
set_env MAIL_MAILER smtp
set_env MAIL_HOST 127.0.0.1
set_env MAIL_PORT 1025
set_env MAIL_FROM_ADDRESS noreply@cevfolio.test
rm -f .env.bak
grep -q '^APP_KEY=.\+' .env || php artisan key:generate --no-interaction

echo "==> 4/5 Migrations (ATTENTION : migrate:fresh efface la base de développement)"
until php artisan migrate:fresh --force --no-interaction 2>/dev/null; do echo "   attente de MySQL..."; sleep 3; done

echo "==> 5/5 Frontend"
cd ../frontend
rm -rf src/App.css src/assets
npm install react-router-dom axios @tanstack/react-query react-hook-form zod @hookform/resolvers
npm install -D tailwindcss @tailwindcss/vite
npm run build

cat << 'MSG'

Terminé.
  make backend   -> http://localhost:8000
  make queue
  make frontend  -> http://localhost:5173  (doit afficher "API Laravel : connectée")
MSG
