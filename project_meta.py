"""
testpi – Gemeinsame Projektmetadaten (eine Quelle).

Projekt:     testpi
Modul:       project_meta.py
Version:     1.0.0
Stand:       2026-09-11
Abhaengig:   POSIX-sh, hostname, date, ip (iproute2), grep, sed, ls; Tests: Python >= 3.10 Stdlib
Bezug:       requirements.txt (leer – kein Python-Laufzeitbedarf)
Lizenz:      MIT
Upstream:    test.sh (FFHB / RadioBBS)
Erstellt mit: Cursor Grok 4.6
Autor:       (FFHB) / RadioBBS

Beschreibung
------------
Zentrale Konstanten fuer Dateikoepfe, CLI und Tests. Werte nicht in den
aufrufenden Dateien abweichend setzen.

Historie
--------
Version 1.0.0 – 2026-09-11 – Erste gemeinsame Metadatenquelle.

Aufruf / Nutzung
----------------
Wird importiert, nicht als Programm gestartet:

    python -c "import project_meta as m; print(m.VERSION, m.STAND)"
"""

from __future__ import annotations

PROJEKT = "testpi"
VERSION = "1.0.0"
STAND = "2026-09-11"
LIZENZ = "MIT"
UPSTREAM = "test.sh (FFHB / RadioBBS)"
AUTOR = "(FFHB) / RadioBBS"
PYTHON_MIN = "3.10"
ERSTELLT_MIT = "Cursor Grok 4.6"
SKRIPT = "testpi.sh"
KOMPAT_SKRIPT = "test.sh"

BESCHREIBUNG = (
    "Gibt Umgebungsdaten eines Linux-Rechners aus, speichert die IP-Adressen "
    "in einer zeitgestempelten Datei und prueft ein Sync-Verzeichnis."
)

ABHAENGIG = (
    "POSIX-sh, hostname, date, ip (iproute2), grep, sed, ls; "
    "Tests: Python >= 3.10 Stdlib"
)
BEZUG = "requirements.txt (leer – kein Python-Laufzeitbedarf)"

DEFAULT_LOGFILE = "testpi.log"
DEFAULT_SYNC_RELATIV = "Desktop/SyncPI"
LOG_STAMP = "%Y-%m-%d %H:%M:%S"
REPOSITORY_URL = "https://github.com/RadioBBS/PiTest"
