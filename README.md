# Turkish Consulate Appointment Checker

Checks the earliest passport renewal appointment at the London Turkish Consulate. Zero dependencies — just `curl` and `bash`.

## Usage

```bash
bash check.sh
```

Check a different consulate or service:

```bash
MISSION_ID=472 bash check.sh          # Edinburg
MISSION_ID=512 bash check.sh          # Manchester
APPOINTMENT_ID=5022 bash check.sh     # Lost passport
```

## GitHub Actions

Runs every 30 minutes on `ubuntu-slim`. Uncomment the Telegram notify step in `.github/workflows/check-appointment.yml` to enable notifications.

## Telegram notifications

1. Message [@BotFather](https://t.me/botfather) on Telegram, send `/newbot`, and copy the token
2. Message your new bot, then message [@userinfobot](https://t.me/userinfobot) to get your chat ID
3. Add these as GitHub repo secrets: `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID`
4. Uncomment the notify step in the workflow
