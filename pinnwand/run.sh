#!/usr/bin/env bash
# Startet die Pinnwand im Home-Assistant-Add-on.
# Programmcode liegt in /data/app (wird aus GitHub geholt und gebaut, nicht gesichert),
# Nutzdaten in /config (= addon_configs, in jeder Home-Assistant-Sicherung enthalten, per Samba erreichbar).
set -uo pipefail

OPTIONS="${OPTIONS_FILE:-/data/options.json}"
APP="${APP_DIR:-/data/app}"
DATA="${DATA_DIR:-/config}"
REPO="github.com/Wurstgulasch84/pinnwand.git"

opt() { jq -r "$1 // empty" "$OPTIONS" 2>/dev/null; }
log() { echo "[pinnwand] $*"; }
wait_forever() { log "$*"; log "Das Add-on wartet. Nach dem Ändern der Konfiguration bitte neu starten."; sleep infinity; }

TOKEN="$(opt .github_token)"
BRANCH="$(opt .branch)"; BRANCH="${BRANCH:-main}"
SOURCE="${SOURCE_URL:-}"   # nur für Tests: anderer Ort für den Programmcode
if [ -z "$SOURCE" ]; then
  if [ -z "$TOKEN" ] && [ ! -f "$APP/.built" ]; then
    wait_forever "Es ist noch kein GitHub-Zugangsschlüssel eingetragen (Reiter „Konfiguration“)."
  fi
  SOURCE="https://x-access-token:${TOKEN}@${REPO}"
fi

mkdir -p "$DATA/database" "$DATA/uploads" "$DATA/backups"

# 1. Neuesten Programmstand holen
if [ ! -d "$APP/.git" ]; then
  log "Lade den Programmcode zum ersten Mal …"
  rm -rf "$APP"
  if ! git clone --quiet --depth 1 --branch "$BRANCH" "$SOURCE" "$APP"; then
    wait_forever "Der Programmcode konnte nicht geladen werden. Stimmt der GitHub-Zugangsschlüssel?"
  fi
  git -C "$APP" remote set-url origin "https://${REPO}"   # Schlüssel nicht in der Konfiguration ablegen
elif [ -n "$TOKEN" ] || [ -n "${SOURCE_URL:-}" ]; then
  log "Suche nach Updates …"
  if git -C "$APP" fetch --quiet --depth 1 "$SOURCE" "$BRANCH"; then
    git -C "$APP" reset --quiet --hard FETCH_HEAD
  else
    log "Keine Verbindung zu GitHub, starte den vorhandenen Stand."
  fi
fi

# 2. Bauen, wenn sich der Stand geändert hat
HEAD="$(git -C "$APP" rev-parse HEAD)"
if [ "$(cat "$APP/.built" 2>/dev/null)" != "$HEAD" ]; then
  log "Baue Programmstand ${HEAD:0:7}. Beim ersten Mal dauert das einige Minuten …"
  cd "$APP"
  if npm ci --no-audit --no-fund --loglevel=error && npm run build --silent; then
    echo "$HEAD" > "$APP/.built"
    log "Fertig gebaut."
  elif [ -f "$APP/.built" ]; then
    log "Bauen ist fehlgeschlagen, starte den letzten funktionierenden Stand."
    git -C "$APP" reset --quiet --hard "$(cat "$APP/.built")"
    npm ci --no-audit --no-fund --loglevel=error
  else
    wait_forever "Bauen ist fehlgeschlagen. Details stehen weiter oben im Protokoll."
  fi
fi

# 3. Starten
cd "$APP"
export NODE_ENV=production
export PORT=3190
export DATABASE_PATH="$DATA/database/database.sqlite"
export UPLOAD_DIR="$DATA/uploads"
export BACKUP_DIR="$DATA/backups"
export PUBLIC_URL="$(opt .public_url)"
export LINK_PREVIEWS="$(opt .link_previews)"
export MAX_UPLOAD_MB="$(opt .max_upload_mb)"
log "Starte die Pinnwand auf Port 3190."
exec node scripts/start-production.mjs
