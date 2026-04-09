#!/usr/bin/env bash
# Run `go mod tidy` in every service so the new socialdev/shared replace
# directive resolves and go.sum is populated. Run this once after pulling
# the event-bus changes (or any time go.mod changes).
set -e
cd "$(dirname "$0")"

for svc in shared login problem activity chat image notification analytics; do
  if [ -f "$svc/go.mod" ]; then
    echo "→ go mod tidy in $svc"
    (cd "$svc" && go mod tidy)
  fi
done
echo "✓ done"
