"""
Scanner: walks BACKUP_DIR, computes checksums, and populates the client
files table. Files whose checksum hasn't changed since the last successful
send are skipped.
"""

import hashlib
import logging
import os
import uuid
from pathlib import Path

from client.db import get_checksum, upsert_file

logger = logging.getLogger(__name__)

CHUNK_SIZE = 1024 * 1024  # 1 MB — read in chunks to avoid loading large files into memory


def compute_checksum(file_path: Path) -> str:
    """Compute the SHA-256 checksum of a file."""
    sha256 = hashlib.sha256()
    with open(file_path, "rb") as f:
        while chunk := f.read(CHUNK_SIZE):
            sha256.update(chunk)
    return sha256.hexdigest()


def scan(backup_dir: str) -> int:
    """
    Walk backup_dir and upsert file records for any new or changed files.
    Returns the number of files queued for sending.
    """
    root = Path(backup_dir)
    if not root.exists():
        logger.error(f"Backup directory does not exist: {backup_dir}")
        return 0

    queued = 0

    for abs_path in root.rglob("*"):
        if not abs_path.is_file():
            continue

        relative_path = str(abs_path.relative_to(root))
        file_size = abs_path.stat().st_size

        checksum = compute_checksum(abs_path)

        # Skip if the file hasn't changed since last successful send
        last_checksum = get_checksum(relative_path)
        if last_checksum == checksum:
            logger.debug(f"Unchanged, skipping: {relative_path}")
            continue

        file_id = str(uuid.uuid4())
        upsert_file(
            file_id=file_id,
            file_path=str(abs_path),
            relative_path=relative_path,
            file_size=file_size,
            checksum=checksum,
        )
        logger.info(f"Queued: {relative_path} ({file_size:,} bytes)")
        queued += 1

    logger.info(f"Scan complete. {queued} file(s) queued for backup.")
    return queued
