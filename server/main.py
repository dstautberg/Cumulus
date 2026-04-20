"""
gRPC Server - Cumulus
Run this file from the repo root: python -m server.main
"""

import grpc
import logging
import os
from concurrent import futures

from dotenv import load_dotenv
from server.db import initialize as init_db
from server.servicers.greeter import GreeterServicer
from server.servicers.registration import RegistrationServicer
from server.servicers.backup import BackupServicer
import helloworld_pb2_grpc
import cumulus_pb2_grpc

load_dotenv()

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
logger = logging.getLogger(__name__)

PORT = int(os.environ.get("SERVER_PORT", 50051))


def serve():
    """Start the gRPC server."""
    init_db()

    server = grpc.server(
        futures.ThreadPoolExecutor(max_workers=10),
        options=[
            ("grpc.max_send_message_length", 50 * 1024 * 1024),   # 50 MB
            ("grpc.max_receive_message_length", 50 * 1024 * 1024), # 50 MB
        ],
    )

    helloworld_pb2_grpc.add_GreeterServicer_to_server(GreeterServicer(), server)
    cumulus_pb2_grpc.add_RegistrationServicer_to_server(RegistrationServicer(), server)
    cumulus_pb2_grpc.add_BackupServicer_to_server(BackupServicer(), server)

    server.add_insecure_port(f"[::]:{PORT}")
    server.start()

    from common.network import get_local_ip
    logger.info(f"gRPC server started, listening on {get_local_ip()}:{PORT}")
    logger.info("Press Ctrl+C to stop.")

    try:
        server.wait_for_termination()
    except KeyboardInterrupt:
        logger.info("Shutting down server...")
        server.stop(grace=5)
        logger.info("Server stopped.")


if __name__ == "__main__":
    serve()
