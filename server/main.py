"""
gRPC Server - Cumulus
Run this file from the repo root: python -m server.main
"""

import os
import grpc
import logging
import dotenv
from concurrent import futures

from server.db import initialize as init_db
from server.servicers.greeter import GreeterServicer
from server.servicers.registration import RegistrationServicer
import helloworld_pb2_grpc
import cumulus_pb2_grpc
from common.network import get_local_ip, get_hostname

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
logger = logging.getLogger(__name__)

dotenv.load_dotenv()
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

    server.add_insecure_port(f"[::]:{PORT}")
    server.start()

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
