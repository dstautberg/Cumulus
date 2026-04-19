"""
Database module for Cumulus server.
Handles SQLite connection and schema initialization.
"""

import sqlite3
import logging
from pathlib import Path

logger = logging.getLogger(__name__)

DB_PATH = Path(__file__).parent.parent / "cumulus.db"


def get_connection() -> sqlite3.Connection:
    """Return a new SQLite connection with row factory set."""
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def initialize():
    """Create tables if they don't already exist."""
    with get_connection() as conn:
        conn.execute("""
            CREATE TABLE IF NOT EXISTS clients (
                id            INTEGER PRIMARY KEY AUTOINCREMENT,
                hostname      TEXT NOT NULL UNIQUE,
                ip_address    TEXT NOT NULL,
                os_platform   TEXT NOT NULL,
                first_seen    TEXT NOT NULL DEFAULT (datetime('now')),
                last_seen     TEXT NOT NULL DEFAULT (datetime('now'))
            )
        """)
        conn.commit()
    logger.info(f"Database initialized at {DB_PATH}")
