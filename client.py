"""
gRPC Client - Greeter Service
Run this file to test the server: python client.py
(Make sure server.py is running first)
"""

import grpc
import logging

import helloworld_pb2
import helloworld_pb2_grpc

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
logger = logging.getLogger(__name__)

SERVER_ADDRESS = "localhost:50051"


def run():
    with grpc.insecure_channel(SERVER_ADDRESS) as channel:
        stub = helloworld_pb2_grpc.GreeterStub(channel)

        # --- Unary RPC ---
        logger.info("=== Unary RPC: SayHello ===")
        response = stub.SayHello(helloworld_pb2.HelloRequest(name="Alice"))
        logger.info(f"Response: {response.message}")

        # --- Server-Streaming RPC ---
        logger.info("\n=== Streaming RPC: SayHelloStream ===")
        responses = stub.SayHelloStream(helloworld_pb2.HelloRequest(name="Bob"))
        for response in responses:
            logger.info(f"Stream response: {response.message}")


if __name__ == "__main__":
    run()
