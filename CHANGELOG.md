# testpi – Changelog

```
testpi – Aenderungsverlauf des Projekts.

Projekt:     testpi
Modul:       CHANGELOG.md
Version:     1.0.0
Stand:       2026-09-11
Abhaengig:   POSIX-sh, hostname, date, ip (iproute2), grep, sed, ls; Tests: Python >= 3.10 Stdlib
Bezug:       requirements.txt (leer – kein Python-Laufzeitbedarf)
Lizenz:      MIT
Upstream:    test.sh (FFHB / RadioBBS)
Erstellt mit: Cursor Grok 4.6
Autor:       (FFHB) / RadioBBS
```

Format: `Version X.Y.Z – YYYY-MM-DD – Beschreibung` (neueste unten).

## Version 1.0.0 – 2026-09-11

- Eigenes Git-Produkt aus dem bisherigen Skript `test.sh`.
- Aufgabe dokumentiert: Umgebung ausgeben, IP-Adressen speichern, Sync-Verzeichnis pruefen.
- CLI: `--help`, `--version`, `--Ende`, `--dry-run`, `--ausgabe`, `--sync-dir`, `--log`.
- Fest verdrahteter Sync-Pfad durch `$HOME/Desktop/SyncPI/<Rechnername>` ersetzt (ueberschreibbar).
- Tests ohne Live-Netzauswertung.
- Oeffentliches GitHub-Repo `RadioBBS/PiTest`, `CITATION.cff`.
- Dateizwecke und GitHub-About in `PROJECT.yaml` (`files:`, `github_about`).
