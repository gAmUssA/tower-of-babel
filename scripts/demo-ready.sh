#!/usr/bin/env bash
# demo-ready.sh — Set up a tmux session for the Tower of Babel demo.
#
# Creates 4 windows:
#   order-service     — Java/Spring Boot  (Kafka producer)
#   inventory-service — Python/FastAPI    (Kafka consumer)
#   analytics-api     — Node.js/Express   (Kafka consumer)
#   scenarios         — Run demo-1..demo-4 from here
#
# Usage: ./scripts/demo-ready.sh [--no-kafka]
#   --no-kafka  Skip Kafka infrastructure check/start

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SESSION="tob"
START_KAFKA=true

# ── colours ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'

info()  { echo -e "${BLUE}$*${NC}"; }
ok()    { echo -e "${GREEN}✅ $*${NC}"; }
warn()  { echo -e "${YELLOW}⚠️  $*${NC}"; }
die()   { echo -e "${RED}❌ $*${NC}" >&2; exit 1; }
hr()    { echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; }

# ── args ───────────────────────────────────────────────────────────────────────
for arg in "$@"; do
  case "$arg" in
    --no-kafka) START_KAFKA=false ;;
    *) die "Unknown argument: $arg" ;;
  esac
done

# ── pre-flight ─────────────────────────────────────────────────────────────────
command -v tmux   &>/dev/null || die "tmux is required but not installed. (brew install tmux)"
command -v docker &>/dev/null || die "docker is required but not installed."

# ── existing session ───────────────────────────────────────────────────────────
if tmux has-session -t "$SESSION" 2>/dev/null; then
  warn "tmux session '$SESSION' already exists."
  read -r -p "  Kill it and start fresh? [y/N] " ans
  if [[ "${ans,,}" == "y" ]]; then
    tmux kill-session -t "$SESSION"
  else
    info "Attaching to existing session..."
    exec tmux attach-session -t "$SESSION"
  fi
fi

# ── kafka infra ────────────────────────────────────────────────────────────────
if $START_KAFKA; then
  info "🔍 Checking Kafka infrastructure..."
  if docker ps --format '{{.Names}}' 2>/dev/null | grep -q "kafka"; then
    ok "Kafka is already running"
  else
    warn "Kafka not running — starting infrastructure (this may take ~30s)..."
    cd "$PROJECT_ROOT" && make setup
  fi
fi

# ── install deps (fast on cache hits) ─────────────────────────────────────────
info "📦 Syncing Python & Node.js dependencies..."
cd "$PROJECT_ROOT" && make install-deps

# ── nvm helper ─────────────────────────────────────────────────────────────────
# Build a shell snippet that activates Node 22 via nvm, used in the analytics window.
NVM_INIT=""
if [ -s "$HOME/.nvm/nvm.sh" ]; then
  NVM_INIT='source "$HOME/.nvm/nvm.sh" 2>/dev/null; nvm use 22 --silent 2>/dev/null || true'
fi

# ── create session ─────────────────────────────────────────────────────────────
info "🚀 Creating tmux session '${SESSION}'..."

# window 1 — Java Order Service
tmux new-session  -d -s "$SESSION" -n "order-service"     -c "$PROJECT_ROOT"
tmux send-keys    -t "$SESSION:order-service"     "make run-order-service" Enter

# window 2 — Python Inventory Service
tmux new-window   -t "$SESSION"    -n "inventory-service" -c "$PROJECT_ROOT"
tmux send-keys    -t "$SESSION:inventory-service" "make run-inventory-service" Enter

# window 3 — Node.js Analytics API (activate Node 22 first if nvm is present)
tmux new-window   -t "$SESSION"    -n "analytics-api"     -c "$PROJECT_ROOT"
if [ -n "$NVM_INIT" ]; then
  tmux send-keys  -t "$SESSION:analytics-api" "$NVM_INIT" Enter
  sleep 0.5
fi
tmux send-keys    -t "$SESSION:analytics-api"     "make run-analytics-api" Enter

# window 4 — Demo scenarios (focus here)
tmux new-window   -t "$SESSION"    -n "scenarios"         -c "$PROJECT_ROOT"
tmux send-keys    -t "$SESSION:scenarios" "make demo-workflow" Enter
tmux select-window -t "$SESSION:scenarios"

# ── summary ────────────────────────────────────────────────────────────────────
hr
echo -e "${GREEN}Session '${SESSION}' is ready.${NC} Services are starting now."
echo ""
echo -e "${YELLOW}Windows  (Ctrl-b n / Ctrl-b p to navigate):${NC}"
echo -e "  ${GREEN}order-service    ${NC} ☕  Java/Spring Boot  — allow ~30-60s to boot"
echo -e "  ${GREEN}inventory-service${NC} 🐍  Python/FastAPI"
echo -e "  ${GREEN}analytics-api    ${NC} 📊  Node.js/Express"
echo -e "  ${GREEN}scenarios        ${NC} 🎭  Run demo commands from here"
echo ""
echo -e "${YELLOW}Scenarios:${NC}"
echo -e "  ${GREEN}make demo-1${NC}  🗼  Tower of Babel   (serialisation chaos)"
echo -e "  ${GREEN}make demo-2${NC}  🐟  Babel Fish       (Avro + Schema Registry)"
echo -e "  ${GREEN}make demo-3${NC}  🔄  Safe Evolution   (schema compatibility)"
echo -e "  ${GREEN}make demo-4${NC}  🛡️   Prevented Disasters (breaking change blocked)"
echo -e "  ${GREEN}make demo-all${NC}    Run all demos in sequence"
hr

# Attach (or switch if already inside tmux)
if [ -n "${TMUX:-}" ]; then
  exec tmux switch-client -t "$SESSION"
else
  exec tmux attach-session -t "$SESSION"
fi
