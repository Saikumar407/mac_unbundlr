"""ProfilePilot Companion API - backend tests"""
import os
import pytest
import requests

BASE_URL = os.environ.get("REACT_APP_BACKEND_URL", "https://workspace-launcher-1.preview.emergentagent.com").rstrip("/")
API = f"{BASE_URL}/api"

VALID_KINDS = {"browserProfile", "app", "url", "shell"}


@pytest.fixture(scope="module")
def client():
    s = requests.Session()
    s.headers.update({"Content-Type": "application/json"})
    return s


# ---------- Root ----------
def test_root(client):
    r = client.get(f"{API}/", timeout=15)
    assert r.status_code == 200
    assert r.json().get("message") == "ProfilePilot Companion API"


# ---------- AI workspace ----------
def _validate_plan(data):
    assert isinstance(data.get("name"), str) and data["name"]
    assert isinstance(data.get("symbol"), str) and data["symbol"]
    assert isinstance(data.get("items"), list) and len(data["items"]) > 0
    for it in data["items"]:
        assert it["kind"] in VALID_KINDS, f"bad kind: {it['kind']}"
        assert isinstance(it["value"], str) and it["value"]
        assert isinstance(it["delayMs"], int)


def test_ai_workspace_laravel(client):
    r = client.post(f"{API}/ai-workspace", json={"prompt": "laravel"}, timeout=60)
    assert r.status_code == 200, r.text
    _validate_plan(r.json())


def test_ai_workspace_nextjs(client):
    r = client.post(f"{API}/ai-workspace", json={"prompt": "nextjs"}, timeout=60)
    assert r.status_code == 200, r.text
    _validate_plan(r.json())


def test_ai_workspace_empty_prompt(client):
    r = client.post(f"{API}/ai-workspace", json={"prompt": ""}, timeout=30)
    assert r.status_code == 400


# ---------- Workspaces export / list ----------
def test_workspace_export_and_list(client):
    payload = {
        "name": "TEST_Workspace",
        "symbol": "square.stack.3d.up",
        "items": [
            {"kind": "app", "value": "/Applications/Visual Studio Code.app", "delayMs": 300, "note": "editor"},
            {"kind": "url", "value": "https://example.com", "delayMs": 500},
        ],
    }
    r = client.post(f"{API}/workspaces/export", json=payload, timeout=15)
    assert r.status_code == 200, r.text
    created = r.json()
    assert created["name"] == "TEST_Workspace"
    assert "id" in created
    wid = created["id"]

    r2 = client.get(f"{API}/workspaces", timeout=15)
    assert r2.status_code == 200
    ids = [w["id"] for w in r2.json()]
    assert wid in ids


# ---------- Status legacy ----------
def test_status_create_and_list(client):
    r = client.post(f"{API}/status", json={"client_name": "TEST_client"}, timeout=15)
    assert r.status_code == 200
    obj = r.json()
    assert obj["client_name"] == "TEST_client"
    assert "id" in obj

    r2 = client.get(f"{API}/status", timeout=15)
    assert r2.status_code == 200
    assert any(c["client_name"] == "TEST_client" for c in r2.json())
