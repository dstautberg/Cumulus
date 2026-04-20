"""
Cumulus Admin Web Interface
Run from the repo root: python -m uvicorn admin.main:app --reload --port 8000
"""

from fastapi import FastAPI
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from pathlib import Path
import sqlite3

from server.db import DB_PATH

app = FastAPI(title="Cumulus Admin")

TEMPLATE_PATH = Path(__file__).parent / "templates" / "index.html"


def get_clients():
    if not DB_PATH.exists():
        return []
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    rows = conn.execute("""
        SELECT hostname, ip_address, os_platform, first_seen, last_seen
        FROM clients
        ORDER BY last_seen DESC
    """).fetchall()
    conn.close()
    return [dict(row) for row in rows]


@app.get("/api/clients")
def api_clients():
    return get_clients()


@app.get("/", response_class=HTMLResponse)
def index():
    # Read template with explicit UTF-8 to avoid platform default (cp1252) decode errors
    return TEMPLATE_PATH.read_text(encoding='utf-8')
