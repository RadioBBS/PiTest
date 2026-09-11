#!/bin/sh
#
# testpi – Automatisierte Pruefung von Syntax, CLI und Dry-Run.
#
# Projekt:     testpi
# Modul:       tests/test_testpi.sh
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
# Prueft testpi.sh ohne Produktionsdaten: sh -n, --help, --version,
# unbekannte Option, Pflichtfelder, LF, --dry-run.
#
# Historie
# --------
# Version 1.0.0 – 2026-09-11 – Erste Testfassung.
#
# Aufruf / Nutzung
# ----------------
#   sh tests/test_testpi.sh
#

VERSION="1.0.0"
VERSION_DATUM="2026-09-11"
fehler=0

repo_wurzel() {
	#
	# Beschreibung: Ermittelt das Projektverzeichnis (Parent von tests/).
	# Parameter:    keine
	# Rueckgabewert: Pfad auf stdout
	# Fehlerfaelle: Fallback .
	# Beispiel:     repo_wurzel
	#
	CDPATH= cd -- "$(dirname -- "$0")/.." 2>/dev/null && pwd || printf '%s\n' "."
}

meld_ok() {
	#
	# Beschreibung: Erfolgsmeldung eines Testschritts.
	# Parameter:    $1 = Text
	# Rueckgabewert: keines
	# Fehlerfaelle: keine
	# Beispiel:     meld_ok "help"
	#
	printf 'OK    %s\n' "$1"
}

meld_fail() {
	#
	# Beschreibung: Fehlerzaehler erhoehen und Meldung ausgeben.
	# Parameter:    $1 = Text
	# Rueckgabewert: keines
	# Fehlerfaelle: keine
	# Beispiel:     meld_fail "CR gefunden"
	#
	printf 'FEHLER %s\n' "$1" >&2
	fehler=$((fehler + 1))
}

ROOT="$(repo_wurzel)"
SKRIPT="${ROOT}/testpi.sh"

cd "$ROOT" || exit 1

if [ ! -f "$SKRIPT" ]; then
	echo "FEHLER: $SKRIPT fehlt." >&2
	exit 1
fi

if sh -n "$SKRIPT"; then
	meld_ok "sh -n testpi.sh"
else
	meld_fail "sh -n testpi.sh"
fi

if sh -n "${ROOT}/test.sh"; then
	meld_ok "sh -n test.sh"
else
	meld_fail "sh -n test.sh"
fi

hilfe="$(sh "$SKRIPT" --help)" || meld_fail "--help Exit-Code"
case "$hilfe" in
	*"testpi ${VERSION}"*) meld_ok "--help enthaelt Version" ;;
	*) meld_fail "--help ohne Versionszeile" ;;
esac
case "$hilfe" in
	*"--dry-run"*) meld_ok "--help nennt --dry-run" ;;
	*) meld_fail "--help ohne --dry-run" ;;
esac

vers="$(sh "$SKRIPT" --version)" || meld_fail "--version Exit-Code"
case "$vers" in
	*"${VERSION} (${VERSION_DATUM})"*) meld_ok "--version" ;;
	*) meld_fail "--version Inhalt" ;;
esac

if sh "$SKRIPT" --unbekannt >/dev/null 2>&1; then
	meld_fail "unbekannte Option muss scheitern"
else
	meld_ok "unbekannte Option -> Fehler"
fi

for feld in Projekt Modul Version Stand Abhaengig Bezug Lizenz Upstream Autor; do
	if grep -q "^# ${feld}:" "$SKRIPT"; then
		meld_ok "Dateikopf $feld"
	else
		meld_fail "Dateikopf $feld fehlt"
	fi
done

if grep -q 'Erstellt mit:' "$SKRIPT"; then
	meld_ok "Dateikopf Erstellt mit"
else
	meld_fail "Dateikopf Erstellt mit fehlt"
fi

tmpd="${TMPDIR:-/tmp}/testpi-test-$$"
mkdir -p "$tmpd/syncziel" || exit 1
if command -v ip >/dev/null 2>&1 && command -v hostname >/dev/null 2>&1; then
	if sh "$SKRIPT" --dry-run --ausgabe "$tmpd/IP-stand.txt" --sync-dir "$tmpd/syncziel" \
		| grep -q DRY-RUN
	then
		meld_ok "--dry-run"
	else
		meld_fail "--dry-run"
	fi
	if [ -f "$tmpd/IP-stand.txt" ]; then
		meld_fail "--dry-run hat Datei geschrieben"
	else
		meld_ok "--dry-run ohne Datei"
	fi
else
	meld_ok "--dry-run uebersprungen (ip/hostname fehlen)"
fi
rm -rf "$tmpd"

cr=$(printf '\r')
for datei in testpi.sh test.sh tests/test_testpi.sh; do
	if grep -q "$cr" "$datei"; then
		meld_fail "CR in $datei (LF erforderlich)"
	else
		meld_ok "LF $datei"
	fi
done

if [ "$fehler" -ne 0 ]; then
	echo "Tests fehlgeschlagen: $fehler" >&2
	exit 1
fi
echo "Alle Tests erfolgreich."
exit 0
