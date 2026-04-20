"""
Client-side database for tracking files to be backed up.
"""

import sqlite3
import logging
from pathlib import Path

logger = logging.getLogger(__name__)

DB_PATH = Path(__file__).parent.parent / "cumulus_client.db"


def get_connection() -> sqlite3.Connection:
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def initialize():
    """Create tables if they don't already exist."""
    with get_connection() as conn:
        conn.execute("""
            CREATE TABLE IF NOT EXISTS files (
                id            INTEGER PRIMARY KEY AUTOINCREMENT,
                file_id       TEXT NOT NULL UNIQUE,
                file_path     TEXT NOT NULL,
                relative_path TEXT NOT NULL,
                file_size     INTEGER NOT NULL,
                checksum      TEXT NOT NULL,
                status        TEXT NOT NULL DEFAULT 'pending',
                last_seen     TEXT NOT NULL DEFAULT (datetime('now')),
                last_sent     TEXT
            )
        """)
        conn.commit()
    logger.info(f"Client database initialized at {DB_PATH}")


def upsert_file(file_id: str, file_path: str, relative_path: str,
                file_size: int, checksum: str):
    """Insert or update a file record."""
    with get_connection() as conn:
        conn.execute("""
            INSERT INTO files (file_id, file_path, relative_path, file_size, checksum, status, last_seen)
            VALUES (?, ?, ?, ?, ?, 'pending', datetime('now'))
            ON CONFLICT(file_id) DO UPDATE SET
                file_size    = excluded.file_size,
                checksum     = excluded.checksum,
                last_seen    = datetime('now')
        """, (file_id, file_path, relative_path, file_size, checksum))
        conn.commit()


def get_checksum(relative_path: str) -> str | None:
    """Return the last known checksum for a file path, or None."""
    with get_connection() as conn:
        row = conn.execute(
            "SELECT checksum FROM files WHERE relative_path = ? AND status = 'sent'",
            (relative_path,)
        ).fetchone()
        return row["checksum"] if row else None


def get_pending_files() -> list:
    """Return all files with status 'pending'."""
    with get_connection() as conn:
        return conn.execute(
            "SELECT * FROM files WHERE status = 'pending' ORDER BY id"
        ).fetchall()


def mark_sent(file_id: str):
    """Mark a file as successfully sent."""
    with get_connection() as conn:
        conn.execute("""
            UPDATE files SET status = 'sent', last_sent = datetime('now')
            WHERE file_id = ?
        """, (file_id,))
        conn.commit()


def mark_failed(file_id: str):
    """Mark a file as failed so it will be retried next run."""
    with get_connection() as conn:
        conn.execute(
            "UPDATE files SET status = 'failed' WHERE file_id = ?",
            (file_id,)
        )
        conn.commit()
