# testpi – Umgebungsdaten ausgeben und IP-Adressen speichern

```
testpi – Umgebungsdaten ausgeben und IP-Adressen speichern.

Projekt:     testpi
Modul:       README.md
Version:     1.0.0
Stand:       2026-09-11
Abhaengig:   POSIX-sh, hostname, date, ip (iproute2), grep, sed, ls; Tests: Python >= 3.10 Stdlib
Bezug:       requirements.txt (leer – kein Python-Laufzeitbedarf)
Lizenz:      MIT
Upstream:    test.sh (FFHB / RadioBBS)
Erstellt mit: Cursor Grok 4.6
Autor:       (FFHB) / RadioBBS
```

## Zweck

Gibt Umgebungsdaten eines Linux-Rechners aus, speichert die IP-Adressen
in einer zeitgestempelten Datei und prueft ein Sync-Verzeichnis.

## Voraussetzungen

- POSIX-Shell (`/bin/sh`) auf Linux (typisch Raspberry Pi OS)
- `hostname`, `date`, `ip` (iproute2), `grep`, `sed`, `ls`
- Entwicklungstests: Python >= 3.10 (nur Standardbibliothek)

Kein fest verdrahteter Benutzer- oder Rechnername. Das Sync-Verzeichnis
liegt standardmaessig unter `$HOME/Desktop/SyncPI/<Rechnername>` und ist
mit `--sync-dir` ueberschreibbar.

## Installation

Skript kopieren (LF-Zeilenenden) und ausfuehrbar machen:

```bash
chmod +x testpi.sh test.sh
```

Keine Extra-Systempakete auf einem typischen Raspberry Pi OS / Debian:
`ip`, `hostname`, `date`, `grep`, `sed` und `ls` sind Bestandteil der
Grundinstallation. Falls `ip` fehlt:

```bash
sudo apt-get install iproute2
```

Abhaengigkeitsdatei auf dem Entwicklungsrechner (No-Op):

```bash
python -m pip install -r requirements.txt
```

## Aufruf / Nutzung

`--help` und `--version` ohne Pflichtprogramme und ohne Dateischreiben.
Der Fachlauf braucht `ip` und schreibt eine Datei ins aktuelle Verzeichnis,
sofern nicht `--dry-run` gesetzt ist:

```bash
./testpi.sh
./testpi.sh --dry-run
./testpi.sh --ausgabe ./IP-stand.txt
./testpi.sh --sync-dir "$HOME/Desktop/SyncPI/$(hostname)"
./testpi.sh --log
./testpi.sh --help
./testpi.sh --version
```

`./test.sh` ruft dieselbe Logik auf (bisheriger Skriptname).

Die Standard-Ausgabedatei heisst `IP-<Rechnername>_<YYYY-MM-DD_HH-MM-SS>.txt`
im aktuellen Arbeitsverzeichnis. `--ausgabe` setzt den vollstaendigen Pfad.

## Risiken

- Die IP-Datei enthaelt Hostnamen und Netzadressen; nicht veroeffentlichen,
  wenn das unerwuenscht ist.
- `--dry-run` schreibt die Datei nicht, zeigt den Inhalt aber an.
- Das Sync-Verzeichnis wird nur geprueft, nicht angelegt oder geaendert.
- Logging (`--log`) schreibt nach `./testpi.log` oder den angegebenen Pfad.

## Tests

```bash
python -m unittest tests.test_testpi
```

Ohne Live-Netzauswertung. Optional mit POSIX-sh: `sh tests/test_testpi.sh`.

## Lizenz

MIT. Siehe `LICENSE`.

Quellcode: https://github.com/RadioBBS/PiTest
