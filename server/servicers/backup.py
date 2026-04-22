"""
Backup servicer: receives file chunks from sending clients and
serves them back to receiving clients.
"""

import grpc
import logging

import cumulus_pb2
import cumulus_pb2_grpc
from server.db import (
    save_chunk, get_chunks_for_file, get_next_file_chunk_metas,
    mark_file_downloaded, file_exists
)

logger = logging.getLogger(__name__)


class BackupServicer(cumulus_pb2_grpc.BackupServicer):

    def SendFile(self, request_iterator, context: grpc.ServicerContext) -> cumulus_pb2.SendFileReply:
        """Receive a stream of chunks from a client and persist them."""
        file_id = None
        chunks_received = 0

        try:
            for chunk in request_iterator:
                if file_id is None:
                    file_id = chunk.file_id
                    logger.info(
                        f"Receiving '{chunk.file_path}' "
                        f"({chunk.total_chunks} chunk(s)) from {chunk.source_hostname}"
                    )

                save_chunk(
                    file_id=chunk.file_id,
                    file_path=chunk.file_path,
                    checksum=chunk.checksum,
                    file_size=chunk.file_size,
                    chunk_index=chunk.chunk_index,
                    total_chunks=chunk.total_chunks,
                    data=chunk.data,
                    source_hostname=chunk.source_hostname,
                )
                chunks_received += 1

            logger.info(f"Stored {chunks_received} chunk(s) for file_id={file_id}")
            return cumulus_pb2.SendFileReply(
                success=True,
                message=f"Received {chunks_received} chunk(s).",
                file_id=file_id,
            )

        except Exception as e:
            logger.error(f"Error receiving file: {e}")
            context.set_code(grpc.StatusCode.INTERNAL)
            context.set_details(str(e))
            return cumulus_pb2.SendFileReply(success=False, message=str(e))

    def GetNextFileChunks(self, request: cumulus_pb2.GetNextFileChunksRequest,
                          context: grpc.ServicerContext) -> cumulus_pb2.GetNextFileChunksReply:
        """Return chunk metadata for the oldest fully-uploaded file."""
        rows = get_next_file_chunk_metas()

        if not rows:
            logger.info("GetNextFileChunks: no files ready for download.")
            return cumulus_pb2.GetNextFileChunksReply(chunks=[])

        chunks = [
            cumulus_pb2.ChunkMeta(
                file_id=row["file_id"],
                file_path=row["file_path"],
                checksum=row["checksum"],
                file_size=row["file_size"],
                chunk_index=row["chunk_index"],
                total_chunks=row["total_chunks"],
                source_hostname=row["source_hostname"],
            )
            for row in rows
        ]

        logger.info(
            f"GetNextFileChunks: returning {len(chunks)} chunk(s) "
            f"for file_id={chunks[0].file_id} path='{chunks[0].file_path}'"
        )
        return cumulus_pb2.GetNextFileChunksReply(chunks=chunks)

    def GetFileChunk(self, request: cumulus_pb2.GetFileChunkRequest,
                     context: grpc.ServicerContext):
        """Stream stored chunks (with data) back to a requesting client."""
        file_id = request.file_id

        if not file_exists(file_id):
            context.set_code(grpc.StatusCode.NOT_FOUND)
            context.set_details(f"No file found with file_id={file_id}")
            return

        chunks = get_chunks_for_file(file_id)
        logger.info(f"GetFileChunk: serving {len(chunks)} chunk(s) for file_id={file_id}")

        for chunk in chunks:
            if not context.is_active():
                break
            yield cumulus_pb2.FileChunk(
                file_id=chunk["file_id"],
                file_path=chunk["file_path"],
                checksum=chunk["checksum"],
                file_size=chunk["file_size"],
                chunk_index=chunk["chunk_index"],
                total_chunks=chunk["total_chunks"],
                data=chunk["data"],
                source_hostname=chunk["source_hostname"],
            )

        mark_file_downloaded(file_id)
        logger.info(f"GetFileChunk: completed file_id={file_id}")
