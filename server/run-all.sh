#!/usr/bin/env bash
# รันทุก Go service พร้อมกัน — log แต่ละตัวมี prefix [service]
# หยุดทั้งหมด: Ctrl+C ครั้งเดียว
set -e
cd "$(dirname "$0")"

SERVICES=(login problem activity chat image notification analytics)
PIDS=()

cleanup() {
  echo ""
  echo "→ stopping all services..."
  for pid in "${PIDS[@]}"; do kill "$pid" 2>/dev/null || true; done
  wait 2>/dev/null || true
  exit 0
}
trap cleanup INT TERM

for svc in "${SERVICES[@]}"; do
  echo "→ starting $svc"
  (cd "$svc" && set -a && [ -f .env ] && . ./.env; set +a; go run . 2>&1 | sed "s/^/[$svc] /") &
  PIDS+=($!)
done

wait
