"""
Uploader: reads pending files from the client DB and streams them
to the server one chunk at a time.
"""

import logging
import math
from pathlib import Path

import cumulus_pb2
import cumulus_pb2_grpc
from client.db import get_pending_files, mark_sent, mark_failed
from common.network import get_hostname

logger = logging.getLogger(__name__)

CHUNK_SIZE = 1024 * 1024  # 1 MB


def _generate_chunks(file_record, hostname: str):
    """Generator that yields FileChunk messages for a single file."""
    file_path = Path(file_record["file_path"])
    file_size = file_record["file_size"]
    total_chunks = max(1, math.ceil(file_size / CHUNK_SIZE))

    with open(file_path, "rb") as f:
        for chunk_index in range(total_chunks):
            data = f.read(CHUNK_SIZE)
            if not data:
                break
            yield cumulus_pb2.FileChunk(
                file_id=file_record["file_id"],
                file_path=file_record["relative_path"],
                checksum=file_record["checksum"],
                file_size=file_size,
                chunk_index=chunk_index,
                total_chunks=total_chunks,
                data=data,
                source_hostname=hostname,
            )


def upload_all(stub: cumulus_pb2_grpc.BackupStub):
    """Upload all pending files to the server."""
    pending = get_pending_files()

    if not pending:
        logger.info("No files pending upload.")
        return

    hostname = get_hostname()
    logger.info(f"Starting upload of {len(pending)} file(s)...")

    for file_record in pending:
        relative_path = file_record["relative_path"]
        file_id = file_record["file_id"]

        try:
            logger.info(f"Uploading: {relative_path}")
            response = stub.SendFile(_generate_chunks(file_record, hostname))

            if response.success:
                mark_sent(file_id)
                logger.info(f"Uploaded successfully: {relative_path}")
            else:
                mark_failed(file_id)
                logger.error(f"Server rejected file {relative_path}: {response.message}")

        except Exception as e:
            mark_failed(file_id)
            logger.error(f"Failed to upload {relative_path}: {e}")

    logger.info("Upload run complete.")
