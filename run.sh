#!/usr/bin/env bash
set -e

cd "$(dirname "$0")"

cleanup() {
  kill "$BACKEND_PID" "$FRONTEND_PID" 2>/dev/null
}
trap cleanup EXIT INT TERM

(cd backend && source venv/bin/activate && python main.py 2>&1 | sed -u 's/^/[backend] /') &
BACKEND_PID=$!

(cd frontend && npm run dev 2>&1 | sed -u 's/^/[frontend] /') &
FRONTEND_PID=$!

wait
