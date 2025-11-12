#!/bin/bash
set -e

APP_DIR="/app/rottenpotatoes"
cd "$APP_DIR"

# Run migrations and seed at container startup
bundle exec rake db:migrate || true
bundle exec rake db:seed || true

PORT="${PORT:-3000}"
exec bundle exec rails server -b 0.0.0.0 -p "$PORT"