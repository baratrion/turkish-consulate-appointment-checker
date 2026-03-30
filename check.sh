#!/usr/bin/env bash
set -euo pipefail

# Mission IDs: Londra=268, Edinburg=472, Manchester=512
MISSION_ID="${MISSION_ID:-268}"
APPOINTMENT_ID="${APPOINTMENT_ID:-5021}"
WORKDIR=$(mktemp -d)
chmod 700 "$WORKDIR"
trap 'rm -rf "$WORKDIR"' EXIT

UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"

# 1. Select consulate (creates session cookie)
curl -sf --max-time 15 -A "$UA" \
  -c "$WORKDIR/cookies" -X POST \
  -d "selectedMission=$MISSION_ID" \
  'https://www.konsolosluk.gov.tr/Home/MissionSelected' > /dev/null \
  || { echo "ERROR: Failed to select consulate"; exit 1; }

# 2. Fetch appointment page
HTML=$(curl -sf --max-time 15 -A "$UA" \
  -b "$WORKDIR/cookies" \
  "https://www.konsolosluk.gov.tr/Appointment/Index/$APPOINTMENT_ID") \
  || { echo "ERROR: Failed to fetch appointment page"; exit 1; }

# Sanity check: response must contain expected marker
if [[ "$HTML" != *"Başkonsolosluğu"* ]]; then
  echo "ERROR: Response does not contain appointment data — session may have expired or site changed"
  exit 1
fi

# Parse: each row has consulate name + date (DD.MM.YYYY)
echo "$HTML" | grep -oE '[A-Za-zçğıöşüÇĞİÖŞÜ ]+ Başkonsolosluğu' | grep -v '^$' > "$WORKDIR/names.txt"
echo "$HTML" | grep -oE '[0-9]{2}\.[0-9]{2}\.[0-9]{4}' | grep -v '^$' > "$WORKDIR/dates.txt"

NAMES_COUNT=$(wc -l < "$WORKDIR/names.txt")
DATES_COUNT=$(wc -l < "$WORKDIR/dates.txt")

if [ "$DATES_COUNT" -eq 0 ]; then
  echo "No appointments found."
  exit 1
fi

if [ "$NAMES_COUNT" -ne "$DATES_COUNT" ]; then
  echo "ERROR: Parsed $NAMES_COUNT consulates but $DATES_COUNT dates — HTML structure may have changed"
  exit 1
fi

echo "=== Passport Renewal — Earliest Appointments ==="
paste -d '|' "$WORKDIR/names.txt" "$WORKDIR/dates.txt" | while IFS='|' read -r name date; do
  printf "  %-30s %s\n" "$name" "$date"
done

# Build formatted message for Telegram
MSG=$'🇹🇷 Passport Renewal Appointments\n\n'
MSG+=$(paste -d '|' "$WORKDIR/names.txt" "$WORKDIR/dates.txt" | while IFS='|' read -r name date; do
  printf '📍 %-14s — %s\n' "${name% Başkonsolosluğu}" "$date"
done)

echo ""
echo "$MSG"

# GitHub Actions output (multiline)
if [ -n "${GITHUB_OUTPUT:-}" ]; then
  {
    echo "summary<<EOF"
    echo "$MSG"
    echo "EOF"
  } >> "$GITHUB_OUTPUT"
fi
