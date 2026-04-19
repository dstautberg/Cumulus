import grpc
import time
import logging

import generated.helloworld_pb2 as helloworld_pb2
import generated.helloworld_pb2_grpc as helloworld_pb2_grpc

logger = logging.getLogger(__name__)


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
