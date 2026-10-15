#!/usr/bin/env bash
#
# monitor.sh — проверка свободного места на диске и свободной памяти.
# Пишет WARNING в лог, если свободно меньше THRESHOLD процентов.
# Предполагается запуск через cron каждые 5 минут.
#
set -uo pipefail

# ---- Настройки ----
MOUNT_POINT="/"                                  # какой раздел проверяем
THRESHOLD=10                                     # порог в процентах
LOG_DIR="/var/log/system-monitor"
LOG_FILE="${LOG_DIR}/monitor.log"

mkdir -p "${LOG_DIR}"

timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

log() {
    local level="$1"
    local message="$2"
    echo "[$(timestamp)] ${level}: ${message}" >> "${LOG_FILE}"
}

# ---- Проверка диска ----
# df -h выводит проценты занятого места (Use%), нам нужен свободный процент
disk_used_percent=$(df --output=pcent "${MOUNT_POINT}" | tail -1 | tr -dc '0-9')
disk_free_percent=$((100 - disk_used_percent))

if (( disk_free_percent < THRESHOLD )); then
    log "WARNING" "Диск ${MOUNT_POINT} — свободно ${disk_free_percent}% (меньше порога ${THRESHOLD}%)!"
else
    log "INFO" "Диск ${MOUNT_POINT} — свободно ${disk_free_percent}%"
fi

# ---- Проверка памяти ----
# free -m: строка Mem: total used free shared buff/cache available
mem_total=$(free -m | awk '/^Mem:/ {print $2}')
mem_available=$(free -m | awk '/^Mem:/ {print $7}')
mem_free_percent=$(( mem_available * 100 / mem_total ))

if (( mem_free_percent < THRESHOLD )); then
    log "WARNING" "Память — доступно ${mem_free_percent}% (меньше порога ${THRESHOLD}%)!"
else
    log "INFO" "Память — доступно ${mem_free_percent}%"
fi

exit 0
