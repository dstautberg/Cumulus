"""
Backup servicer: receives file chunks from sending clients and
serves them back to receiving clients.
"""

import grpc
import logging

import cumulus_pb2
import cumulus_pb2_grpc
from server.db import (
    save_chunk, get_chunks_for_file, mark_file_downloaded,
    file_exists
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
                        f"Receiving file '{chunk.file_path}' "
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

    def FetchFile(self, request: cumulus_pb2.FetchFileRequest, context: grpc.ServicerContext):
        """Stream stored chunks back to a requesting client."""
        file_id = request.file_id

        if not file_exists(file_id):
            context.set_code(grpc.StatusCode.NOT_FOUND)
            context.set_details(f"No file found with file_id={file_id}")
            return

        chunks = get_chunks_for_file(file_id)
        logger.info(f"Serving {len(chunks)} chunk(s) for file_id={file_id}")

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
        logger.info(f"File served successfully: file_id={file_id}")
