"""
testpi – Unittests ohne Live-Netzauswertung.

Projekt:     testpi
Modul:       tests/test_testpi.py
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
Prueft Metadatenabgleich, Dateikoepfe, LF-Zeilenenden und CLI
(--help/--version/--dry-run) ohne Produktionsdaten.

Historie
--------
Version 1.0.0 – 2026-09-11 – Erste Testfassung.

Aufruf / Nutzung
----------------
  python -m unittest tests.test_testpi
"""

from __future__ import annotations

import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

import project_meta as meta  # noqa: E402

SKRIPT = ROOT / meta.SKRIPT
PFLICHTFELDER = (
    "Projekt",
    "Modul",
    "Version",
    "Stand",
    "Abhaengig",
    "Bezug",
    "Lizenz",
    "Upstream",
    "Erstellt mit",
    "Autor",
)
KOPF_DATEIEN = (
    meta.SKRIPT,
    meta.KOMPAT_SKRIPT,
    "project_meta.py",
    "PROJECT.yaml",
    "pyproject.toml",
    "requirements.txt",
    "README.md",
    "CHANGELOG.md",
    "LICENSE",
    "CITATION.cff",
    ".gitignore",
    ".gitattributes",
    "tests/__init__.py",
    "tests/test_testpi.py",
    "tests/test_testpi.sh",
    ".github/workflows/ci.yml",
)


def yaml_value(text: str, key: str) -> str:
    """Liest einen einzeiligen YAML-Schluessel.

    Parameter:
        text: Dateiinhalt
        key: Schluessel
    Rueckgabewert:
        Wert oder leer
    Fehlerfaelle:
        keine
    Beispiel:
        yaml_value('version: "1.0.0"', "version")
    """
    for line in text.splitlines():
        if line.startswith("#") or ":" not in line:
            continue
        left, right = line.split(":", 1)
        if left.strip() == key:
            return right.strip().strip('"').strip("'")
    return ""


def find_posix_sh() -> str | None:
    """Sucht eine POSIX-Shell fuer Skriptlaeufe.

    Parameter:
        keine
    Rueckgabewert:
        'wsl-sh' oder Pfad, sonst None
    Fehlerfaelle:
        keine
    Beispiel:
        find_posix_sh()
    """
    if shutil.which("wsl"):
        try:
            probe = subprocess.run(
                ["wsl", "sh", "-c", "echo ok"],
                capture_output=True,
                text=True,
                timeout=20,
                check=False,
            )
            if probe.returncode == 0 and "ok" in (probe.stdout or ""):
                return "wsl-sh"
        except (OSError, subprocess.TimeoutExpired):
            pass
    for name in ("sh", "bash"):
        found = shutil.which(name)
        if found and "WindowsApps" not in found:
            return found
    program_files = Path(os.environ.get("PROGRAMFILES", ""))
    git_sh = program_files / "Git" / "bin" / "sh.exe"
    if git_sh.is_file():
        return str(git_sh)
    return None


def to_shell_path(path: str, shell_mode: str) -> str:
    """Wandelt Windows-Pfade fuer WSL um.

    Parameter:
        path: lokaler Pfad
        shell_mode: find_posix_sh()-Ergebnis
    Rueckgabewert:
        Pfad fuer die Shell
    Fehlerfaelle:
        keine
    Beispiel:
        to_shell_path(r"C:\\tmp\\a", "wsl-sh")
    """
    if shell_mode != "wsl-sh":
        return path
    p = Path(path)
    if p.drive:
        rest = p.as_posix()
        return "/mnt/" + rest[0].lower() + rest[2:]
    return path.replace("\\", "/")


def run_script(shell: str, extra: list[str], cwd: Path | None = None) -> subprocess.CompletedProcess[str]:
    """Startet testpi.sh mit den angegebenen Argumenten.

    Parameter:
        shell: POSIX-Shell oder wsl-sh
        extra: Argumente nach dem Skriptpfad
        cwd: Arbeitsverzeichnis
    Rueckgabewert:
        CompletedProcess
    Fehlerfaelle:
        subprocess-Fehler
    Beispiel:
        run_script(sh, ["--help"])
    """
    work = cwd if cwd is not None else ROOT
    mapped = [to_shell_path(a, shell) for a in extra]
    if shell == "wsl-sh":
        cmd = ["wsl", "sh", to_shell_path(str(SKRIPT), shell), *mapped]
    else:
        cmd = [shell, str(SKRIPT), *mapped]
    return subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        check=False,
        cwd=str(work),
        encoding="utf-8",
        errors="replace",
    )


class MetaTests(unittest.TestCase):
    """Abgleich PROJECT.yaml / pyproject.toml / Dateikoepfe."""

    def test_versions_match(self) -> None:
        """Eine Versionsnummer in YAML, TOML, Meta und Skript.

        Parameter:
            keine
        Rueckgabewert:
            keine
        Fehlerfaelle:
            AssertionError
        Beispiel:
            test_versions_match()
        """
        yaml_text = (ROOT / "PROJECT.yaml").read_text(encoding="utf-8")
        toml = (ROOT / "pyproject.toml").read_text(encoding="utf-8")
        script = SKRIPT.read_text(encoding="utf-8")
        self.assertEqual(yaml_value(yaml_text, "version"), meta.VERSION)
        self.assertEqual(yaml_value(yaml_text, "stand"), meta.STAND)
        self.assertIn(meta.BESCHREIBUNG, yaml_text)
        self.assertIn(f'version = "{meta.VERSION}"', toml)
        self.assertIn(meta.BESCHREIBUNG, toml)
        self.assertIn(f'VERSION="{meta.VERSION}"', script)
        self.assertIn(f'VERSION_DATUM="{meta.STAND}"', script)
        self.assertIn(meta.BESCHREIBUNG, script)
        self.assertEqual(meta.PROJEKT, "testpi")
        self.assertEqual(meta.AUTOR, "(FFHB) / RadioBBS")
        self.assertEqual(meta.LIZENZ, "MIT")
        self.assertEqual(meta.DEFAULT_LOGFILE, "testpi.log")
        cff = (ROOT / "CITATION.cff").read_text(encoding="utf-8")
        self.assertIn(f'version: "{meta.VERSION}"', cff)
        self.assertIn(meta.BESCHREIBUNG, cff)
        self.assertIn(meta.REPOSITORY_URL, cff)
        self.assertIn("https://github.com/RadioBBS/PiTest", yaml_text)
        self.assertIn("visibility: public", yaml_text)

    def test_headers_present(self) -> None:
        """Pflichtfelder in allen Projektdateien.

        Parameter:
            keine
        Rueckgabewert:
            keine
        Fehlerfaelle:
            AssertionError
        Beispiel:
            test_headers_present()
        """
        for rel in KOPF_DATEIEN:
            path = ROOT / rel
            self.assertTrue(path.is_file(), f"fehlt: {rel}")
            text = path.read_text(encoding="utf-8")
            if rel == "LICENSE":
                self.assertIn("MIT License", text)
            for feld in PFLICHTFELDER:
                self.assertIn(feld, text, f"{rel} ohne {feld}")
            self.assertIn(meta.VERSION, text)
            self.assertIn(meta.STAND, text)

    def test_shell_lf(self) -> None:
        """Unix-Skripte ohne CR.

        Parameter:
            keine
        Rueckgabewert:
            keine
        Fehlerfaelle:
            AssertionError
        Beispiel:
            test_shell_lf()
        """
        for rel in (meta.SKRIPT, meta.KOMPAT_SKRIPT, "tests/test_testpi.sh"):
            data = (ROOT / rel).read_bytes()
            self.assertNotIn(b"\r", data, f"CR in {rel}")

    def test_no_hardcoded_user_path(self) -> None:
        """Kein fest verdrahteter Anmeldename im Skript.

        Parameter:
            keine
        Rueckgabewert:
            keine
        Fehlerfaelle:
            AssertionError
        Beispiel:
            test_no_hardcoded_user_path()
        """
        script = SKRIPT.read_text(encoding="utf-8")
        self.assertNotIn("C:\\Users\\", script)
        self.assertNotIn("C:/Users/", script)
        self.assertNotIn("/home/pi/", script)


@unittest.skipUnless(find_posix_sh(), "keine POSIX-Shell gefunden")
class ScriptTests(unittest.TestCase):
    """CLI ohne Live-Netz mit POSIX-sh."""

    @classmethod
    def setUpClass(cls) -> None:
        """Merkt die gefundene Shell.

        Parameter:
            keine
        Rueckgabewert:
            keine
        Fehlerfaelle:
            Skip wenn keine Shell
        Beispiel:
            setUpClass()
        """
        cls.shell = find_posix_sh()

    def test_help_and_version(self) -> None:
        """--help und --version enthalten Stand und Beschreibung.

        Parameter:
            keine
        Rueckgabewert:
            keine
        Fehlerfaelle:
            AssertionError
        Beispiel:
            test_help_and_version()
        """
        help_run = run_script(self.shell, ["--help"])
        self.assertEqual(help_run.returncode, 0, help_run.stderr)
        self.assertIn(meta.VERSION, help_run.stdout)
        self.assertIn(meta.BESCHREIBUNG, help_run.stdout)
        self.assertIn("--dry-run", help_run.stdout)
        self.assertIn("./testpi.sh --help", help_run.stdout)
        vers = run_script(self.shell, ["--version"])
        self.assertEqual(vers.returncode, 0, vers.stderr)
        self.assertIn(f"{meta.VERSION} ({meta.STAND})", vers.stdout)
        self.assertIn(meta.BESCHREIBUNG, vers.stdout)

    def test_unknown_option(self) -> None:
        """Unbekannte Option liefert Exit 2.

        Parameter:
            keine
        Rueckgabewert:
            keine
        Fehlerfaelle:
            AssertionError
        Beispiel:
            test_unknown_option()
        """
        proc = run_script(self.shell, ["--unbekannt"])
        self.assertEqual(proc.returncode, 2, proc.stderr)
        self.assertIn("FEHLER:", proc.stderr)

    def test_missing_ausgabe_value(self) -> None:
        """--ausgabe ohne Wert liefert Exit 2.

        Parameter:
            keine
        Rueckgabewert:
            keine
        Fehlerfaelle:
            AssertionError
        Beispiel:
            test_missing_ausgabe_value()
        """
        proc = run_script(self.shell, ["--ausgabe"])
        self.assertEqual(proc.returncode, 2, proc.stderr)
        self.assertIn("FEHLER:", proc.stderr)

    def test_dry_run(self) -> None:
        """--dry-run schreibt keine Datei, wenn ip verfuegbar ist.

        Parameter:
            keine
        Rueckgabewert:
            keine
        Fehlerfaelle:
            AssertionError; Skip ohne ip
        Beispiel:
            test_dry_run()
        """
        with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as tmp:
            tmp_path = Path(tmp)
            ziel = tmp_path / "IP-stand.txt"
            sync = tmp_path / "syncziel"
            sync.mkdir()
            proc = run_script(
                self.shell,
                [
                    "--dry-run",
                    "--ausgabe",
                    str(ziel),
                    "--sync-dir",
                    str(sync),
                ],
                cwd=ROOT,
            )
            if proc.returncode == 1 and "Pflichtprogramm fehlt" in proc.stderr:
                self.skipTest("ip/hostname nicht im PATH (Fachlauf)")
            self.assertEqual(proc.returncode, 0, proc.stderr + proc.stdout)
            self.assertIn("DRY-RUN", proc.stdout)
            self.assertFalse(ziel.is_file(), "Dry-Run darf die IP-Datei nicht anlegen")
            self.assertIn("vorhanden", proc.stdout)


if __name__ == "__main__":
    unittest.main()
