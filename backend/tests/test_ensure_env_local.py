"""
Tests for the bootstrap.sh env-local fix.

Covers:
- .gitignore no longer excludes ProfilePilot/scripts/.env.local.example
- ensure-env-local.sh three scenarios (both missing / example present / idempotent)
- bootstrap.sh delegates to ensure-env-local.sh
- .env.local.example real-file contents
- smoke-test.sh regression
"""
import os
import shutil
import subprocess
from pathlib import Path

import pytest

REPO = Path("/app")
PP = REPO / "ProfilePilot"
HELPER = PP / "scripts" / "ensure-env-local.sh"
EXAMPLE = PP / "scripts" / ".env.local.example"
BOOTSTRAP = PP / "scripts" / "bootstrap.sh"
SMOKE = PP / "scripts" / "smoke-test.sh"

REQUIRED_KEYS = [
    "DEVELOPER_ID_APPLICATION",
    "DEVELOPMENT_TEAM",
    "NOTARY_KEYCHAIN_PROFILE",
    "APPLE_ID",
    "APPLE_APP_SPECIFIC_PASSWORD",
    "SPARKLE_ED_PUBLIC_KEY",
    "APPCAST_URL",
]


def _stage_helper(tmp_path: Path) -> Path:
    """Copy helper into a fresh tmp dir structure mimicking repo layout."""
    scripts_dir = tmp_path / "scripts"
    scripts_dir.mkdir(parents=True, exist_ok=True)
    dest = scripts_dir / "ensure-env-local.sh"
    shutil.copy2(HELPER, dest)
    os.chmod(dest, 0o755)
    return dest


# --- Fix A: .gitignore no longer excludes example -----------------------------
class TestGitignore:
    def test_check_ignore_returns_negation_or_not_ignored(self):
        """git check-ignore should either not match (exit 1) or match a negation."""
        result = subprocess.run(
            ["git", "check-ignore", "-v", "ProfilePilot/scripts/.env.local.example"],
            cwd=REPO,
            capture_output=True,
            text=True,
        )
        # Exit 1 = not ignored (best case). Exit 0 = matched; must be a negation.
        if result.returncode == 0:
            # Output format: .gitignore:LINE:PATTERN\tPATH
            assert "!" in result.stdout, (
                f"Expected negation rule, got: {result.stdout!r}"
            )
        else:
            assert result.returncode == 1, (
                f"Unexpected git check-ignore output: rc={result.returncode} "
                f"stdout={result.stdout!r} stderr={result.stderr!r}"
            )

    def test_git_status_ignored_does_not_list_example(self):
        result = subprocess.run(
            ["git", "status", "--ignored", "--porcelain"],
            cwd=REPO,
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0
        # Ignored files are marked with '!!' prefix
        for line in result.stdout.splitlines():
            if line.startswith("!!") and "ProfilePilot/scripts/.env.local.example" in line:
                pytest.fail(f"example file listed as ignored: {line}")


# --- Fix B: both missing → inline template -----------------------------------
class TestScenarioBothMissing:
    def test_creates_env_local_with_all_keys(self, tmp_path):
        _stage_helper(tmp_path)
        env_local = tmp_path / "scripts" / ".env.local"
        assert not env_local.exists()
        assert not (tmp_path / "scripts" / ".env.local.example").exists()

        result = subprocess.run(
            ["bash", "scripts/ensure-env-local.sh"],
            cwd=tmp_path,
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0, (
            f"stdout={result.stdout!r} stderr={result.stderr!r}"
        )
        assert env_local.exists()
        content = env_local.read_text()
        for key in REQUIRED_KEYS:
            assert key in content, f"Missing key {key} in inline template"


# --- Fix C: example present, local missing → copy example --------------------
class TestScenarioExamplePresent:
    def test_copies_from_example(self, tmp_path):
        _stage_helper(tmp_path)
        example = tmp_path / "scripts" / ".env.local.example"
        example.write_text("MARKER_FROM_EXAMPLE=1\n")
        env_local = tmp_path / "scripts" / ".env.local"
        assert not env_local.exists()

        result = subprocess.run(
            ["bash", "scripts/ensure-env-local.sh"],
            cwd=tmp_path,
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0, (
            f"stdout={result.stdout!r} stderr={result.stderr!r}"
        )
        assert env_local.exists()
        assert "MARKER_FROM_EXAMPLE=1" in env_local.read_text()


# --- Fix D: idempotent — does not overwrite existing -------------------------
class TestScenarioIdempotent:
    def test_does_not_overwrite_existing(self, tmp_path):
        _stage_helper(tmp_path)
        env_local = tmp_path / "scripts" / ".env.local"
        env_local.write_text("MARKER_FROM_USER=1\n")

        result = subprocess.run(
            ["bash", "scripts/ensure-env-local.sh"],
            cwd=tmp_path,
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0
        assert env_local.read_text() == "MARKER_FROM_USER=1\n"


# --- Fix E: real example still exists & has expected keys --------------------
class TestRealExampleFile:
    def test_exists_with_all_keys(self):
        assert EXAMPLE.exists(), f"{EXAMPLE} missing"
        content = EXAMPLE.read_text()
        for key in REQUIRED_KEYS:
            assert key in content, f"Missing key {key} in {EXAMPLE}"


# --- Fix F: bootstrap.sh delegates -------------------------------------------
class TestBootstrapDelegates:
    def test_bootstrap_calls_helper(self):
        content = BOOTSTRAP.read_text()
        assert "ensure-env-local.sh" in content, (
            "bootstrap.sh does not reference ensure-env-local.sh"
        )

    def test_bootstrap_no_fragile_inline_cp(self):
        content = BOOTSTRAP.read_text()
        # The fragile line was: cp scripts/.env.local.example scripts/.env.local
        forbidden = "cp scripts/.env.local.example scripts/.env.local"
        assert forbidden not in content, (
            f"bootstrap.sh still has fragile inline cp: {forbidden!r}"
        )


# --- Regression: smoke-test.sh ------------------------------------------------
class TestSmokeRegression:
    def test_smoke_test_passes(self):
        if not SMOKE.exists():
            pytest.skip("smoke-test.sh not present")
        result = subprocess.run(
            ["bash", "scripts/smoke-test.sh"],
            cwd=PP,
            capture_output=True,
            text=True,
            timeout=120,
        )
        combined = result.stdout + result.stderr
        # Expect a "PASS  N checks green" line with N >= 32
        import re
        m = re.search(r"PASS\s+(\d+)\s+checks?\s+green", combined)
        assert result.returncode == 0, (
            f"smoke-test.sh failed rc={result.returncode}\n{combined[-2000:]}"
        )
        assert m, f"No 'PASS  N checks green' line in output:\n{combined[-2000:]}"
        n = int(m.group(1))
        assert n >= 32, f"Expected >= 32 checks, got {n}"
