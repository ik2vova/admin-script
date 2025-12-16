#!/bin/bash

MAIL_TO="mv@ik2.ru"
FROM_ADDR="pve@ik2.ru"
HOSTNAME="$(hostname)"
DATE="$(date '+%Y-%m-%d %H:%M:%S')"

LOG="/var/log/pve-vm-inventory.log"
TMPMAIL="/tmp/pve-vm-inventory-mail.$$"

{
  echo "====== PVE VM Inventory on $HOSTNAME ======"
  echo "Date: $DATE"
  echo

  echo "ID   Name                 Status    CPUs  RAM(MB)"
  echo "----------------------------------------------------"

  # пропускаем заголовок qm list (NR>1)
  qm list | awk 'NR>1 {print $1}' | while read -r VMID; do
    # имя и статус из qm list
    LINE=$(qm list | awk -v id="$VMID" '$1==id {print}')
    NAME=$(echo "$LINE" | awk '{print $2}')
    STATUS=$(echo "$LINE" | awk '{print $3}')

    # значения из конфигурации ВМ
    CONF="/etc/pve/qemu-server/${VMID}.conf"
    CPUS=$(awk -F '[:= ]+' '/^cores[=:]/ {print $2}' "$CONF" 2>/dev/null)
    SOCKETS=$(awk -F '[:= ]+' '/^sockets[=:]/ {print $2}' "$CONF" 2>/dev/null)
    RAM=$(awk -F '[:= ]+' '/^memory[=:]/ {print $2}' "$CONF" 2>/dev/null)

    [ -z "$CPUS" ] && CPUS=1
    [ -z "$SOCKETS" ] && SOCKETS=1
    [ -z "$RAM" ] && RAM="?"

    TOTALCPU=$((CPUS * SOCKETS))

    printf "%-4s %-20s %-9s %-5s %-7s\n" "$VMID" "$NAME" "$STATUS" "$TOTALCPU" "$RAM"
  done

} > "$LOG" 2>&1

SUBJECT="PVE VM inventory: $HOSTNAME"

{
  echo "Subject: $SUBJECT"
  echo "To: $MAIL_TO"
  echo "From: $FROM_ADDR"
  echo
  cat "$LOG"
} > "$TMPMAIL"

msmtp -a pve "$MAIL_TO" < "$TMPMAIL"

rm -f "$TMPMAIL"
