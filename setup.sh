#!/usr/bin/env bash
# ============================================================
# Sole Store — One-command local setup
# Usage: bash setup.sh   (works from ANY directory)
# ============================================================
set -e

# Always cd into the folder containing this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
ok()    { echo -e "${GREEN}[ OK ]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERR ]${NC} $1"; exit 1; }

echo ""
echo -e "${BLUE}╔══════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       SOLE STORE — LOCAL SETUP       ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════╝${NC}"
echo -e "  Working directory: ${SCRIPT_DIR}"
echo ""

# ── 1. Check Python ──────────────────────────────────────────
info "Checking Python version..."
python3 --version >/dev/null 2>&1 || error "Python 3 not found."
ok "Python found: $(python3 --version)"

# ── 2. Check MySQL CLI ───────────────────────────────────────
info "Checking MySQL CLI..."
mysql --version >/dev/null 2>&1 && ok "MySQL CLI found." || warn "mysql CLI not found — make sure MySQL server is running."

# ── 3. Check Redis ───────────────────────────────────────────
info "Checking Redis..."
redis-cli ping >/dev/null 2>&1 && ok "Redis is running." || warn "Redis not responding — start it with: redis-server"

# ── 4. .env file ─────────────────────────────────────────────
if [ ! -f ".env" ]; then
  info "Creating .env from .env.example..."
  if [ ! -f ".env.example" ]; then
    error ".env.example not found in ${SCRIPT_DIR}. Make sure you extracted the zip correctly."
  fi
  cp .env.example .env
  echo ""
  warn "Please edit .env and set MYSQL_PASSWORD, then re-run this script."
  echo ""
  echo "  Quick edit:  nano ${SCRIPT_DIR}/.env"
  echo "  Then re-run: bash ${SCRIPT_DIR}/setup.sh"
  echo ""
  exit 0
fi
ok ".env file found."

# ── 5. Parse .env safely ─────────────────────────────────────
while IFS='=' read -r key value; do
  [[ "$key" =~ ^#.*$ || -z "$key" ]] && continue
  value="${value%%#*}"
  value="${value%"${value##*[![:space:]]}"}"
  export "$key=$value"
done < .env

# ── 6. Virtual environment ───────────────────────────────────
if [ ! -d "venv" ]; then
  info "Creating virtual environment..."
  python3 -m venv venv
fi
ok "Virtual environment ready."

# ── 7. Install dependencies ──────────────────────────────────
info "Installing Python dependencies..."
source venv/bin/activate
pip install -q --upgrade pip
pip install -q -r requirements.txt
ok "Dependencies installed."

# ── 8. Create database & seed ────────────────────────────────
info "Setting up MySQL database..."
DB_HOST="${MYSQL_HOST:-localhost}"
DB_PORT="${MYSQL_PORT:-3306}"
DB_USER="${MYSQL_USER:-root}"
DB_PASS="${MYSQL_PASSWORD:-}"

if [ -n "$DB_PASS" ]; then
  MYSQL_CMD="mysql -h${DB_HOST} -P${DB_PORT} -u${DB_USER} -p${DB_PASS}"
else
  MYSQL_CMD="mysql -h${DB_HOST} -P${DB_PORT} -u${DB_USER}"
fi

info "Connecting as '${DB_USER}' @ ${DB_HOST}:${DB_PORT} ..."
if $MYSQL_CMD < schema.sql; then
  ok "Database 'sole_store' created and seeded!"
else
  error "DB setup failed — check MYSQL_USER / MYSQL_PASSWORD in .env and ensure MySQL is running."
fi

# ── 9. Launch ────────────────────────────────────────────────
echo ""
echo -e "${GREEN}╔══════════════════════════════════════╗${NC}"
echo -e "${GREEN}║      ALL SET!  STARTING APP...       ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════╝${NC}"
echo ""
echo -e "  Open: ${BLUE}http://localhost:5000${NC}"
echo ""
python app.py
