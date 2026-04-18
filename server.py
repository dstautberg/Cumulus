"""
gRPC Server - Greeter Service
Run this file to start the server: python server.py
"""

import grpc
import time
import logging
from concurrent import futures

import helloworld_pb2
import helloworld_pb2_grpc

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
logger = logging.getLogger(__name__)

PORT = 50051


class GreeterServicer(helloworld_pb2_grpc.GreeterServicer):
    """Implements the Greeter gRPC service."""

    def SayHello(self, request: helloworld_pb2.HelloRequest, context: grpc.ServicerContext) -> helloworld_pb2.HelloReply:
        """Unary RPC: receives one request, returns one response."""
        name = request.name or "World"
        logger.info(f"SayHello called with name='{name}'")
        return helloworld_pb2.HelloReply(message=f"Hello, {name}!")

    def SayHelloStream(self, request: helloworld_pb2.HelloRequest, context: grpc.ServicerContext):
        """Server-streaming RPC: receives one request, streams multiple responses."""
        name = request.name or "World"
        logger.info(f"SayHelloStream called with name='{name}'")

        greetings = [
            f"Hello, {name}!",
            f"Greetings, {name}!",
            f"Good day, {name}!",
            f"Howdy, {name}!",
            f"Salutations, {name}!",
        ]

        for greeting in greetings:
            if context.is_active():
                yield helloworld_pb2.HelloReply(message=greeting)
                time.sleep(0.5)  # Simulate streaming delay


def serve():
    """Start the gRPC server."""
    server = grpc.server(
        futures.ThreadPoolExecutor(max_workers=10),
        options=[
            ("grpc.max_send_message_length", 50 * 1024 * 1024),   # 50 MB
            ("grpc.max_receive_message_length", 50 * 1024 * 1024), # 50 MB
        ],
    )

    helloworld_pb2_grpc.add_GreeterServicer_to_server(GreeterServicer(), server)

    server.add_insecure_port(f"[::]:{PORT}")
    server.start()

    logger.info(f"gRPC server started, listening on port {PORT}")
    logger.info("Press Ctrl+C to stop.")

    try:
        server.wait_for_termination()
    except KeyboardInterrupt:
        logger.info("Shutting down server...")
        server.stop(grace=5)  # 5-second grace period for in-flight requests
        logger.info("Server stopped.")


if __name__ == "__main__":
    serve()
