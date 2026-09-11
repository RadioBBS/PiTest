#!/bin/sh
#
# testpi.sh – Umgebungsdaten ausgeben und IP-Adressen speichern.
#
# Projekt:     testpi
# Modul:       testpi.sh
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
# Typischer Einsatz: Raspberry Pi, der seinen Netzstand und ein
# Sync-Ordner unter Desktop/SyncPI/<Rechnername> dokumentiert.
#
# Historie
# --------
# Version 1.0.0 – 2026-09-11 – Styleguide 2.0.2: CLI, Dry-Run, portable
#                              Sync-Pruefung, Git-Produkt aus test.sh.
#
# Aufruf / Nutzung
# ----------------
#   ./testpi.sh
#   ./testpi.sh --dry-run
#   ./testpi.sh --ausgabe ./IP-stand.txt
#   ./testpi.sh --sync-dir "$HOME/Desktop/SyncPI/$(hostname)"
#   ./testpi.sh --log
#   ./testpi.sh --help
#   ./testpi.sh --version
#

VERSION="1.0.0"
VERSION_DATUM="2026-09-11"
SKRIPTNAME="${0##*/}"
END_PROMPT='Programmende: "Hit any Key or Enter"'
BESCHREIBUNG="Gibt Umgebungsdaten eines Linux-Rechners aus, speichert die IP-Adressen in einer zeitgestempelten Datei und prueft ein Sync-Verzeichnis."

DEFAULT_LOGFILE="testpi.log"
DEFAULT_SYNC_RELATIV="Desktop/SyncPI"

dry_run="false"
warte_am_ende="false"
logging_aktiv="false"
ausgabe_datei=""
sync_dir=""
LOGDATEI="./${DEFAULT_LOGFILE}"
rest_args=""

# ---------------------------------------------------------------------------
# Hilfsfunktionen
# ---------------------------------------------------------------------------

zeitstempel() {
	#
	# Beschreibung: Liefert den aktuellen Zeitstempel fuer Logzeilen.
	# Parameter:    keine
	# Rueckgabewert: YYYY-MM-DD HH:MM:SS auf stdout
	# Fehlerfaelle: date fehlt -> Platzhalter
	# Beispiel:     zeitstempel
	#
	date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || printf '%s\n' '0000-00-00 00:00:00'
}

dateiname_stempel() {
	#
	# Beschreibung: Zeitstempel fuer den Standard-IP-Dateinamen.
	# Parameter:    keine
	# Rueckgabewert: YYYY-MM-DD_HH-MM-SS auf stdout
	# Fehlerfaelle: date fehlt -> Platzhalter
	# Beispiel:     dateiname_stempel
	#
	date '+%Y-%m-%d_%H-%M-%S' 2>/dev/null || printf '%s\n' '0000-00-00_00-00-00'
}

log_nachricht() {
	#
	# Beschreibung: Schreibt eine Logzeile, falls Logging aktiv ist.
	# Parameter:    $1 = Meldung (keine Geheimnisse)
	# Rueckgabewert: keines
	# Fehlerfaelle: Schreibfehler werden ignoriert
	# Beispiel:     log_nachricht "Starte"
	#
	if [ "$logging_aktiv" != "true" ]; then
		return 0
	fi
	printf '%s %s\n' "$(zeitstempel)" "$1" >> "$LOGDATEI" 2>/dev/null || true
}

info_meldung() {
	#
	# Beschreibung: Info auf stdout und optional ins Log.
	# Parameter:    $1 = Text
	# Rueckgabewert: keines
	# Fehlerfaelle: keine
	# Beispiel:     info_meldung "Datei geschrieben"
	#
	printf '%s\n' "$1"
	log_nachricht "$1"
}

warte_auf_ende() {
	#
	# Beschreibung: Wartet auf Enter, wenn --Ende gesetzt ist.
	# Parameter:    keine
	# Rueckgabewert: keines
	# Fehlerfaelle: read ohne TTY wird ignoriert
	# Beispiel:     warte_auf_ende
	#
	if [ "$warte_am_ende" != "true" ]; then
		return 0
	fi
	printf '%s\n' "$END_PROMPT"
	read -r _ || true
}

beende() {
	#
	# Beschreibung: Optionale Tastenwarte und Exit.
	# Parameter:    $1 = Exit-Code (Standard 0)
	# Rueckgabewert: beendet das Skript
	# Fehlerfaelle: finaler Abbruch
	# Beispiel:     beende 0
	#
	warte_auf_ende
	exit "${1:-0}"
}

beende_mit_fehler() {
	#
	# Beschreibung: Zentrale Fehlerbehandlung auf stderr.
	# Parameter:    $1 = Exit-Code, $2 = Meldung
	# Rueckgabewert: beendet das Skript
	# Fehlerfaelle: finaler Abbruch
	# Beispiel:     beende_mit_fehler 2 "Unbekannte Option"
	#
	printf 'FEHLER: %s\n' "$2" >&2
	printf 'Naechster Schritt: %s --help\n' "$0" >&2
	log_nachricht "FEHLER $2"
	beende "$1"
}

zeige_version() {
	#
	# Beschreibung: Version, Datum und Ein-Satz-Zweck auf stdout.
	# Parameter:    keine
	# Rueckgabewert: keines
	# Fehlerfaelle: keine
	# Beispiel:     zeige_version
	#
	echo "testpi $VERSION ($VERSION_DATUM)"
	echo "$BESCHREIBUNG"
}

zeige_hilfe() {
	#
	# Beschreibung: Programmbeschreibung, Parameter und Beispiele ohne Fachlauf.
	# Parameter:    keine
	# Rueckgabewert: keines
	# Fehlerfaelle: keine
	# Beispiel:     zeige_hilfe
	#
	cat << EOF
testpi $VERSION ($VERSION_DATUM)
$BESCHREIBUNG

Verwendung:
  $0
  $0 --dry-run
  $0 --ausgabe ./IP-stand.txt
  $0 --sync-dir "\$HOME/Desktop/SyncPI/\$(hostname)"
  $0 --log
  $0 --help | -h | --Hilfe
  $0 --version

Parameter:
  (ohne)               Umgebung, Netzadressen und Sync-Pruefung
                       Typ: Aktion, Standard: Fachlauf
                       Beispiel: $0
  -o, --ausgabe DATEI  Zieldatei fuer die IP-Liste
                       Typ: Pfad, Standard: ./IP-<Rechner>_<Zeitstempel>.txt
                       Beispiel: $0 --ausgabe ./IP-stand.txt
  --sync-dir PFAD      Zu pruefendes Sync-Verzeichnis
                       Typ: Pfad, Standard: \$HOME/Desktop/SyncPI/<Rechnername>
                       Beispiel: $0 --sync-dir "\$HOME/Desktop/SyncPI/\$(hostname)"
  --dry-run            Ausgabe ohne Datei zu schreiben
                       Typ: Schalter, Standard: aus
                       Beispiel: $0 --dry-run
  --log [DATEI]        Datei-Log (UTF-8, Zeitstempel YYYY-MM-DD HH:MM:SS)
                       Typ: Schalter/Pfad, Standard: aus / $DEFAULT_LOGFILE
                       Beispiel: $0 --log
  -h, --help, --Hilfe  Diese Hilfe anzeigen
                       Typ: Schalter
                       Beispiel: $0 --help
  --version            Version und Datum anzeigen
                       Typ: Schalter
                       Beispiel: $0 --version
  -E, --Ende           Am Ende auf Taste/Enter warten
                       Typ: Schalter, Standard: aus
                       Beispiel: $0 --Ende

Beispiele:
  ./testpi.sh
  ./testpi.sh --dry-run
  ./testpi.sh --ausgabe ./IP-stand.txt
  ./testpi.sh --sync-dir "\$HOME/Desktop/SyncPI/\$(hostname)"
  ./testpi.sh --log
  ./testpi.sh --help
  ./testpi.sh --version
EOF
}

verlange_wert() {
	#
	# Beschreibung: Prueft, dass nach einer Option noch ein Wert folgt.
	# Parameter:    $1 = Optionsname, $2 = Folgewert
	# Rueckgabewert: keines
	# Fehlerfaelle: fehlender Wert -> Exit 2
	# Beispiel:     verlange_wert --ausgabe "$2"
	#
	if [ -z "$2" ]; then
		beende_mit_fehler 2 "Option $1 erwartet einen Wert. Siehe --help."
	fi
}

verarbeite_argumente() {
	#
	# Beschreibung: Liest CLI-Argumente und setzt Laufzeitflags.
	# Parameter:    alle Aufrufargumente
	# Rueckgabewert: keines; setzt globale Flags
	# Fehlerfaelle: unbekannte Option oder fehlender Wert -> Exit 2
	# Beispiel:     verarbeite_argumente "$@"
	#
	while [ $# -gt 0 ]; do
		case "$1" in
			-h|--help|--Hilfe)
				zeige_hilfe
				beende 0
				;;
			--version)
				zeige_version
				beende 0
				;;
			--Ende|-E)
				warte_am_ende="true"
				shift
				;;
			--dry-run)
				dry_run="true"
				shift
				;;
			-o|--ausgabe)
				verlange_wert "$1" "${2:-}"
				ausgabe_datei="$2"
				shift 2
				;;
			--sync-dir)
				verlange_wert "$1" "${2:-}"
				sync_dir="$2"
				shift 2
				;;
			--log)
				logging_aktiv="true"
				case "${2:-}" in
					""|-*) ;;
					*)
						LOGDATEI="$2"
						shift
						;;
				esac
				shift
				;;
			--)
				shift
				break
				;;
			-*)
				beende_mit_fehler 2 "Unbekannte Option: $1"
				;;
			*)
				# Freie Argumente wie im Ursprungsskript anzeigen, nicht als Option werten.
				if [ -z "$rest_args" ]; then
					rest_args="$1"
				else
					rest_args="$rest_args $1"
				fi
				shift
				;;
		esac
	done
	while [ $# -gt 0 ]; do
		if [ -z "$rest_args" ]; then
			rest_args="$1"
		else
			rest_args="$rest_args $1"
		fi
		shift
	done
}

befehl_vorhanden() {
	#
	# Beschreibung: Prueft, ob ein Pflichtprogramm im PATH liegt.
	# Parameter:    $1 = Befehlsname
	# Rueckgabewert: 0 vorhanden, 1 fehlt
	# Fehlerfaelle: keine
	# Beispiel:     befehl_vorhanden ip
	#
	command -v "$1" >/dev/null 2>&1
}

pruefe_abhaengigkeiten() {
	#
	# Beschreibung: Pflichtprogramme vor dem Fachlauf pruefen.
	# Parameter:    keine
	# Rueckgabewert: keines
	# Fehlerfaelle: fehlendes Werkzeug -> Exit 1 plus Installationshinweis
	# Beispiel:     pruefe_abhaengigkeiten
	#
	fehlend=""
	for cmd in hostname date ip grep sed ls; do
		if ! befehl_vorhanden "$cmd"; then
			if [ -z "$fehlend" ]; then
				fehlend="$cmd"
			else
				fehlend="$fehlend $cmd"
			fi
		fi
	done
	if [ -n "$fehlend" ]; then
		printf 'FEHLER: Pflichtprogramm fehlt: %s\n' "$fehlend" >&2
		printf 'Naechster Schritt: sudo apt-get install iproute2 hostname coreutils grep sed\n' >&2
		beende 1
	fi
}

setze_defaults() {
	#
	# Beschreibung: Setzt Ausgabe- und Sync-Pfade, sofern nicht per Option gesetzt.
	# Parameter:    keine
	# Rueckgabewert: keines; setzt ausgabe_datei und sync_dir
	# Fehlerfaelle: hostname fehlgeschlagen -> Exit 1
	# Beispiel:     setze_defaults
	#
	rechner=$(hostname 2>/dev/null) || beende_mit_fehler 1 "Rechnername konnte nicht ermittelt werden."
	if [ -z "$ausgabe_datei" ]; then
		ausgabe_datei="./IP-${rechner}_$(dateiname_stempel).txt"
	fi
	if [ -z "$sync_dir" ]; then
		# Bisher fest verdrahtet auf den Desktop-Sync-Ordner des Anmeldenamens;
		# jetzt portabel ueber HOME und per --sync-dir ueberschreibbar.
		sync_dir="${HOME}/${DEFAULT_SYNC_RELATIV}/${rechner}"
	fi
}

sammle_netzadressen() {
	#
	# Beschreibung: Liest Interface- und Adresszeilen von ip.
	# Parameter:    keine
	# Rueckgabewert: gefilterter Adresstext auf stdout
	# Fehlerfaelle: ip fehlgeschlagen -> Exit 1
	# Beispiel:     sammle_netzadressen
	#
	# Ursprung: ip -a address, gefiltert auf Schnittstellen- und inet-Zeilen.
	ip -a address 2>/dev/null | grep -E ": |inet |inet6 " | sed '/: /i\\' || \
		beende_mit_fehler 1 "Netzadressen konnten nicht gelesen werden (ip)."
}

zeige_umgebung() {
	#
	# Beschreibung: Schreibt die Umgebungsdaten auf stdout (urspruengliche Ausgabe).
	# Parameter:    $1 = Rechnername
	# Rueckgabewert: keines
	# Fehlerfaelle: keine
	# Beispiel:     zeige_umgebung "raspi"
	#
	benutzer="${USER:-}"
	if [ -z "$benutzer" ]; then
		benutzer=$(id -un 2>/dev/null || printf '%s\n' "unbekannt")
	fi
	info_meldung "*----------*"
	info_meldung "Skriptname: $0"
	info_meldung "Benutzer: $benutzer"
	info_meldung "Home-Verzeichnis: ${HOME:-}"
	info_meldung "Aktuelles Verzeichnis: ${PWD:-}"
	info_meldung "Argumente: $ALLE_ARGS"
	info_meldung "Anzahl Argumente: $ALLE_ANZAHL"
	info_meldung "*----------*"
	info_meldung "Rechnername: $1 | Benutzer: $benutzer | Datum: $(date)"
	info_meldung "*----------*"
}

zeige_arbeitsverzeichnis() {
	#
	# Beschreibung: Listet das aktuelle Verzeichnis (Fachinformation, nicht Auswertung).
	# Parameter:    keine
	# Rueckgabewert: keines
	# Fehlerfaelle: ls fehlgeschlagen -> Warnung, kein Abbruch
	# Beispiel:     zeige_arbeitsverzeichnis
	#
	info_meldung "*----------*"
	ls -l || printf 'Warnung: Verzeichnislisting nicht verfuegbar.\n' >&2
	info_meldung "*----------*"
}

schreibe_ipdatei() {
	#
	# Beschreibung: Schreibt die Netzadressen in die Ausgabedatei, ausser bei Dry-Run.
	# Parameter:    $1 = Dateipfad, $2 = Adresstext
	# Rueckgabewert: keines
	# Fehlerfaelle: Schreibfehler -> Exit 1
	# Beispiel:     schreibe_ipdatei "./IP-host.txt" "$inet"
	#
	info_meldung "*----------*"
	info_meldung "$1"
	info_meldung "*----------*"
	printf '%s\n' "$2"
	if [ "$dry_run" = "true" ]; then
		info_meldung "DRY-RUN: Datei nicht geschrieben: $1"
		return 0
	fi
	printf '%s\n' "$2" > "$1" || beende_mit_fehler 1 "Konnte Datei nicht schreiben: $1"
	info_meldung "IP-Liste geschrieben: $1"
}

pruefe_sync_verzeichnis() {
	#
	# Beschreibung: Meldet, ob das Sync-Verzeichnis existiert.
	# Parameter:    $1 = Pfad
	# Rueckgabewert: keines (kein Fehler, nur Status)
	# Fehlerfaelle: keine
	# Beispiel:     pruefe_sync_verzeichnis "$HOME/Desktop/SyncPI/raspi"
	#
	if [ -d "$1" ]; then
		info_meldung "Verzeichnis $1 vorhanden."
	else
		info_meldung "Verzeichnis $1 nicht vorhanden."
	fi
}

hauptdurchlauf() {
	#
	# Beschreibung: Fachlauf: Umgebung, Netzadressen, Datei, Sync-Pruefung.
	# Parameter:    keine
	# Rueckgabewert: keines
	# Fehlerfaelle: Abhaengigkeiten oder I/O -> Exit 1
	# Beispiel:     hauptdurchlauf
	#
	pruefe_abhaengigkeiten
	setze_defaults
	rechner=$(hostname)
	log_nachricht "Start $SKRIPTNAME $VERSION"
	zeige_umgebung "$rechner"
	info_meldung "*----------*"
	info_meldung "$(dateiname_stempel)"
	inet=$(sammle_netzadressen)
	schreibe_ipdatei "$ausgabe_datei" "$inet"
	zeige_arbeitsverzeichnis
	pruefe_sync_verzeichnis "$sync_dir"
	info_meldung "*----------*"
	log_nachricht "Ende Exit 0"
}

# ---------------------------------------------------------------------------
# Hauptprogramm
# ---------------------------------------------------------------------------

trap 'beende 1' HUP INT TERM

ALLE_ARGS="$*"
ALLE_ANZAHL=$#
verarbeite_argumente "$@"
hauptdurchlauf
beende 0
