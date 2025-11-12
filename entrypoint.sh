#!/bin/bash
set -e

APP_DIR="/app/rottenpotatoes"
cd "$APP_DIR"

# Optional runtime migrations:
# bundle exec rake db:migrate || true

PORT="${PORT:-3000}"
exec bundle exec rails server -b 0.0.0.0 -p "$PORT"
