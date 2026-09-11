#!/bin/sh
#
# testpi – Kompatibilitaetsaufruf (leitet an testpi.sh weiter).
#
# Projekt:     testpi
# Modul:       test.sh
# Version:     1.0.0
# Stand:       2026-09-11
# Abhaengig:   POSIX-sh, hostname, date, ip (iproute2), grep, sed, ls; Tests: Python >= 3.10 Stdlib
# Bezug:       requirements.txt (leer – kein Python-Laufzeitbedarf)
# Lizenz:      MIT
# Upstream:    test.sh (FFHB / RadioBBS)
# Erstellt mit: Cursor Grok 4.6
# Autor:       (FFHB) / RadioBBS
#
# Beschreibung
# ------------
# Gibt Umgebungsdaten eines Linux-Rechners aus, speichert die IP-Adressen
# in einer zeitgestempelten Datei und prueft ein Sync-Verzeichnis.
# Behaelt den bisherigen Aufruf ./test.sh; die Fachlogik liegt in testpi.sh.
#
# Historie
# --------
# Version 1.0.0 – 2026-09-11 – Wrapper auf testpi.sh (bisheriges Skript).
#
# Aufruf / Nutzung
# ----------------
#   ./test.sh
#   ./test.sh --dry-run
#   ./test.sh --ausgabe ./IP-stand.txt
#   ./test.sh --sync-dir "$HOME/Desktop/SyncPI/$(hostname)"
#   ./test.sh --log
#   ./test.sh --help
#   ./test.sh --version
#

hier=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd) || exit 1
exec "$hier/testpi.sh" "$@"
