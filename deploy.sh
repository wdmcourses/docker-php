#!/bin/bash
set -e

# === CONFIG ===
SSH_USER="user"
SSH_HOST="example.com"
SERVER_PATH="/home/user/project"
SERVER_URL="https://example.com"

PROD_DB_USER="dbuser"
PROD_DB_PASS="dbpassword"
PROD_DB_NAME="dbname"
PROD_DB_HOST="localhost"

RSYNC_EXCLUDES=".env.local .env.*.local .git .gitignore var/cache/dev var/log docker-compose.* Dockerfile *.md deploy.sh"

# === 1. Symfony cache (remove for non-Symfony) ===
docker compose exec -T -w /var/www web php bin/console cache:clear --env=prod --no-debug --no-interaction
docker compose exec -T -w /var/www web php bin/console cache:warmup --env=prod --no-interaction

# === 2. Export DB ===
echo "[2/5] Export DB..."
docker compose exec -T db mariadb-dump -u root -proot example --no-tablespaces 2>/dev/null \
  | sed 's/utf8mb4_uca1400_\(ai\|as\)_ci/utf8mb4_unicode_ci/g' \
  > /tmp/deploy_dump.sql

# === 3. Rsync ===
echo "[3/5] Rsync..."
EXCLUDE_ARGS=""
for p in $RSYNC_EXCLUDES; do EXCLUDE_ARGS="$EXCLUDE_ARGS --exclude=$p"; done
rsync -avz --delete $EXCLUDE_ARGS ./www/ "${SSH_USER}@${SSH_HOST}:${SERVER_PATH}/"

# === 4. Import DB ===
echo "[4/5] Import DB..."
scp /tmp/deploy_dump.sql "${SSH_USER}@${SSH_HOST}:/tmp/_db.sql"
ssh "${SSH_USER}@${SSH_HOST}" "
  mysql -u ${PROD_DB_USER} -p'${PROD_DB_PASS}' -h ${PROD_DB_HOST} -e 'SET FOREIGN_KEY_CHECKS=0;' ${PROD_DB_NAME} 2>/dev/null
  for t in \$(mysql -u ${PROD_DB_USER} -p'${PROD_DB_PASS}' -h ${PROD_DB_HOST} -N -e 'SHOW TABLES' ${PROD_DB_NAME}); do
    mysql -u ${PROD_DB_USER} -p'${PROD_DB_PASS}' -h ${PROD_DB_HOST} -e \"DROP TABLE IF EXISTS \\\`\$t\\\`\" ${PROD_DB_NAME}
  done
  mysql -u ${PROD_DB_USER} -p'${PROD_DB_PASS}' -h ${PROD_DB_HOST} ${PROD_DB_NAME} < /tmp/_db.sql 2>&1
  rm -f /tmp/_db.sql
"

# === 5. Cleanup ===
echo "[5/5] Cleanup..."
rm -f /tmp/deploy_dump.sql

echo "Done: ${SERVER_URL}"
