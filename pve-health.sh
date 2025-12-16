#!/bin/bash

MAIL_TO="mv@ik2.ru"
FROM_ADDR="pve@ik2.ru"
HOSTNAME="$(hostname)"
DATE="$(date '+%Y-%m-%d %H:%M:%S')"

LOG="/var/log/pve-health.log"
TMPMAIL="/tmp/pve-health-mail.$$"

{
  echo "====== PVE Health Check on $HOSTNAME ======"
  echo "Date: $DATE"
  echo

  echo "---- UPTIME ----"
  uptime
  echo

  echo "---- LOAD AVERAGE ----"
  cat /proc/loadavg
  echo

  echo "---- MEMORY (free -h) ----"
  free -h
  echo

  echo "---- DISK USAGE (df -h) ----"
  df -h
  echo

  echo "---- TOP 5 CPU PROCESSES ----"
  ps -eo pid,comm,%cpu,%mem --sort=-%cpu | head -n 6
  echo

  echo "---- TOP 5 MEM PROCESSES ----"
  ps -eo pid,comm,%cpu,%mem --sort=-%mem | head -n 6
  echo

} > "$LOG" 2>&1

SUBJECT="PVE daily health check: $HOSTNAME"

{
  echo "Subject: $SUBJECT"
  echo "To: $MAIL_TO"
  echo "From: $FROM_ADDR"
  echo
  cat "$LOG"
} > "$TMPMAIL"

# отправка письма через msmtp (аккаунт pve в /etc/msmtprc)
msmtp -a pve "$MAIL_TO" < "$TMPMAIL"

rm -f "$TMPMAIL"
