#!/bin/bash

MAIL_TO="mv@ik2.ru"
FROM_ADDR="pve@ik2.ru"
HOSTNAME="$(hostname)"
DATE="$(date '+%Y-%m-%d %H:%M:%S')"

LOG="/var/log/pve-backup-check.log"
TMPMAIL="/tmp/pve-backup-check-mail.$$"

{
  echo "====== PVE Backup Status on $HOSTNAME ======"
  echo "Date: $DATE"
  echo

  echo "---- Last vzdump tasks (limit 20) ----"
  # фильтруем только строки с vzdump
  pvesh get /nodes/$HOSTNAME/tasks --limit 50 2>/dev/null | \
    grep "vzdump" || echo "No vzdump tasks found"
  echo

  echo "---- Failed or error jobs ----"
  # показываем только строки, где статус не OK
  pvesh get /nodes/$HOSTNAME/tasks --limit 50 2>/dev/null | \
    awk '/vzdump/ && $NF != "OK" {print}' || echo "No failed jobs"
  echo

} > "$LOG" 2>&1

SUBJECT="PVE backup status (last tasks): $HOSTNAME"

{
  echo "Subject: $SUBJECT"
  echo "To: $MAIL_TO"
  echo "From: $FROM_ADDR"
  echo
  cat "$LOG"
} > "$TMPMAIL"

msmtp -a pve "$MAIL_TO" < "$TMPMAIL"

rm -f "$TMPMAIL"
