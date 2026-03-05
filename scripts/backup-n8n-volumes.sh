#!/bin/sh
# Backup / restore Docker named volumes สำหรับ n8n (n8n_1_data, n8n_2_data, ...)
# ใช้เมื่อ deploy ใช้ named volumes จาก generate-compose.py
#
# Usage:
#   ./scripts/backup-n8n-volumes.sh backup   [BACKUP_DIR]
#   ./scripts/backup-n8n-volumes.sh restore  [BACKUP_DIR]
#
# Default BACKUP_DIR = โฟลเดอร์ repo/backups
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BACKUP_DIR_DEFAULT="$REPO_ROOT/backups"

ACTION="${1:-backup}"
if [ "$ACTION" = "backup" ] || [ "$ACTION" = "restore" ]; then
  BACKUP_DIR="${2:-$BACKUP_DIR_DEFAULT}"
else
  echo "Usage: $0 backup [BACKUP_DIR] | restore [BACKUP_DIR]" >&2
  exit 1
fi
mkdir -p "$BACKUP_DIR"

list_volumes() {
  docker volume ls --format '{{.Name}}' | grep -E '^n8n_[0-9]+_data$' | sort -V
}

if [ "$ACTION" = "backup" ]; then
  echo "Backing up n8n volumes to $BACKUP_DIR"
  for vol in $(list_volumes); do
    echo "  $vol ..."
    docker run --rm -v "$vol:/data:ro" -v "$BACKUP_DIR:/out" alpine tar czf "/out/${vol}.tar.gz" -C /data .
  done
  echo "Done. Files: $BACKUP_DIR/n8n_*_data.tar.gz"
elif [ "$ACTION" = "restore" ]; then
  echo "Restoring n8n volumes from $BACKUP_DIR"
  for f in "$BACKUP_DIR"/n8n_*_data.tar.gz; do
    [ -f "$f" ] || continue
    vol=$(basename "$f" .tar.gz)
    echo "  $vol ..."
    docker volume create "$vol" 2>/dev/null || true
    docker run --rm -v "$vol:/data" -v "$BACKUP_DIR:/in:ro" alpine sh -c "tar xzf /in/$(basename "$f") -C /data"
  done
  echo "Done. Restart stack: docker compose -f docker-compose.yml -f docker-compose.generated.yml up -d"
fi
