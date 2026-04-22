"""
Server-side database for client registry and chunk storage.
"""

import sqlite3
import logging
from pathlib import Path

logger = logging.getLogger(__name__)

DB_PATH = Path(__file__).parent.parent / "cumulus_server.db"


def get_connection() -> sqlite3.Connection:
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def initialize():
    """Create tables if they don't already exist."""
    with get_connection() as conn:
        conn.execute("""
            CREATE TABLE IF NOT EXISTS clients (
                id          INTEGER PRIMARY KEY AUTOINCREMENT,
                hostname    TEXT NOT NULL UNIQUE,
                ip_address  TEXT NOT NULL,
                os_platform TEXT NOT NULL,
                first_seen  TEXT NOT NULL DEFAULT (datetime('now')),
                last_seen   TEXT NOT NULL DEFAULT (datetime('now'))
            )
        """)
        conn.execute("""
            CREATE TABLE IF NOT EXISTS chunks (
                id              INTEGER PRIMARY KEY AUTOINCREMENT,
                file_id         TEXT NOT NULL,
                file_path       TEXT NOT NULL,
                checksum        TEXT NOT NULL,
                file_size       INTEGER NOT NULL,
                chunk_index     INTEGER NOT NULL,
                total_chunks    INTEGER NOT NULL,
                data            BLOB NOT NULL,
                source_hostname TEXT NOT NULL,
                received_at     TEXT NOT NULL DEFAULT (datetime('now')),
                downloaded_at   TEXT,
                UNIQUE(file_id, chunk_index)
            )
        """)
        conn.commit()
    logger.info(f"Server database initialized at {DB_PATH}")


def save_chunk(file_id: str, file_path: str, checksum: str, file_size: int,
               chunk_index: int, total_chunks: int, data: bytes,
               source_hostname: str):
    """Persist a single chunk to the database."""
    with get_connection() as conn:
        conn.execute("""
            INSERT OR REPLACE INTO chunks
                (file_id, file_path, checksum, file_size, chunk_index,
                 total_chunks, data, source_hostname)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """, (file_id, file_path, checksum, file_size, chunk_index,
              total_chunks, data, source_hostname))
        conn.commit()


def get_next_file_chunk_metas() -> list:
    """
    Return chunk metadata (no data) for the oldest fully-uploaded file.
    A file is considered complete when the number of received chunks
    equals total_chunks. Returns an empty list if no files are ready.
    """
    with get_connection() as conn:
        return conn.execute("""
            SELECT file_id, file_path, checksum, file_size,
                   chunk_index, total_chunks, source_hostname
            FROM chunks
            WHERE file_id = (
                SELECT file_id
                FROM chunks
                WHERE downloaded_at IS NULL
                GROUP BY file_id
                HAVING COUNT(*) = MAX(total_chunks)
                ORDER BY file_id ASC
                LIMIT 1
            )
            ORDER BY chunk_index ASC
        """).fetchall()


def get_chunks_for_file(file_id: str) -> list:
    """Return all chunks (including data) for a file, ordered by chunk_index."""
    with get_connection() as conn:
        return conn.execute(
            "SELECT * FROM chunks WHERE file_id = ? ORDER BY chunk_index",
            (file_id,)
        ).fetchall()


def file_exists(file_id: str) -> bool:
    """Return True if any chunks exist for the given file_id."""
    with get_connection() as conn:
        row = conn.execute(
            "SELECT 1 FROM chunks WHERE file_id = ? LIMIT 1", (file_id,)
        ).fetchone()
        return row is not None


def mark_file_downloaded(file_id: str):
    """Record the download timestamp on all chunks for a file."""
    with get_connection() as conn:
        conn.execute("""
            UPDATE chunks SET downloaded_at = datetime('now')
            WHERE file_id = ?
        """, (file_id,))
        conn.commit()


def purge_expired_chunks(retention_days: int):
    """Delete chunks that were downloaded more than retention_days ago."""
    with get_connection() as conn:
        result = conn.execute("""
            DELETE FROM chunks
            WHERE downloaded_at IS NOT NULL
            AND downloaded_at <= datetime('now', ? || ' days')
        """, (f"-{retention_days}",))
        conn.commit()
    if result.rowcount:
        logger.info(f"Purged {result.rowcount} expired chunk(s).")
