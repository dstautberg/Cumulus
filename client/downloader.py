"""
Downloader: fetches the next available file from the server and
writes it to RESTORE_DIR, mirroring the original directory structure.
"""

import hashlib
import logging
import os
from pathlib import Path

import cumulus_pb2
import cumulus_pb2_grpc

logger = logging.getLogger(__name__)


def _compute_checksum(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def download_next(stub: cumulus_pb2_grpc.BackupStub, restore_dir: str) -> bool:
    """
    Fetch and save the next available file from the server.
    Returns True if a file was downloaded, False if none were available.
    """
    # Step 1: get chunk metadata for the next available file
    reply = stub.GetNextFileChunks(cumulus_pb2.GetNextFileChunksRequest())

    if not reply.chunks:
        logger.info("No files available for download.")
        return False

    first = reply.chunks[0]
    file_id    = first.file_id
    file_path  = first.file_path
    expected_checksum = first.checksum
    total_chunks = first.total_chunks

    logger.info(
        f"Downloading '{file_path}' "
        f"({total_chunks} chunk(s)) from {first.source_hostname}"
    )

    # Step 2: verify the manifest is complete before fetching data
    received_indexes = {c.chunk_index for c in reply.chunks}
    expected_indexes = set(range(total_chunks))
    if received_indexes != expected_indexes:
        missing = expected_indexes - received_indexes
        logger.error(f"Incomplete manifest for '{file_path}': missing chunk(s) {missing}")
        return False

    # Step 3: stream the actual chunk data
    chunks_data = {}
    for chunk in stub.GetFileChunk(cumulus_pb2.GetFileChunkRequest(file_id=file_id)):
        chunks_data[chunk.chunk_index] = chunk.data

    if len(chunks_data) != total_chunks:
        logger.error(
            f"Expected {total_chunks} chunk(s) but received {len(chunks_data)} "
            f"for '{file_path}'"
        )
        return False

    # Step 4: reassemble in order
    file_bytes = b"".join(chunks_data[i] for i in range(total_chunks))

    # Step 5: verify checksum
    actual_checksum = _compute_checksum(file_bytes)
    if actual_checksum != expected_checksum:
        logger.error(
            f"Checksum mismatch for '{file_path}': "
            f"expected {expected_checksum}, got {actual_checksum}"
        )
        return False

    # Step 6: write to RESTORE_DIR mirroring the original structure
    dest_path = Path(restore_dir) / file_path
    dest_path.parent.mkdir(parents=True, exist_ok=True)
    dest_path.write_bytes(file_bytes)

    logger.info(f"Saved to: {dest_path}")
    return True


def download_all(stub: cumulus_pb2_grpc.BackupStub, restore_dir: str):
    """Keep downloading files until the server has none left."""
    total = 0
    while download_next(stub, restore_dir):
        total += 1
    logger.info(f"Download run complete. {total} file(s) restored.")
