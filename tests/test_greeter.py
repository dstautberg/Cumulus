"""
Unit tests for the GreeterServicer.
Run from the repo root: python -m pytest tests/
"""

import unittest
from unittest.mock import MagicMock

from server.servicers.greeter import GreeterServicer
import helloworld_pb2 as helloworld_pb2


class TestSayHello(unittest.TestCase):

    def setUp(self):
        self.servicer = GreeterServicer()
        self.context = MagicMock()

    def test_say_hello_with_name(self):
        request = helloworld_pb2.HelloRequest(name="Alice")
        response = self.servicer.SayHello(request, self.context)
        self.assertEqual(response.message, "Hello, Alice!")

    def test_say_hello_empty_name_defaults_to_world(self):
        request = helloworld_pb2.HelloRequest(name="")
        response = self.servicer.SayHello(request, self.context)
        self.assertEqual(response.message, "Hello, World!")


class TestSayHelloStream(unittest.TestCase):

    def setUp(self):
        self.servicer = GreeterServicer()
        self.context = MagicMock()
        self.context.is_active.return_value = True

    def test_stream_returns_five_greetings(self):
        request = helloworld_pb2.HelloRequest(name="Bob")
        responses = list(self.servicer.SayHelloStream(request, self.context))
        self.assertEqual(len(responses), 5)

    def test_stream_greetings_contain_name(self):
        request = helloworld_pb2.HelloRequest(name="Bob")
        responses = list(self.servicer.SayHelloStream(request, self.context))
        for response in responses:
            self.assertIn("Bob", response.message)

    def test_stream_stops_when_context_inactive(self):
        self.context.is_active.return_value = False
        request = helloworld_pb2.HelloRequest(name="Bob")
        responses = list(self.servicer.SayHelloStream(request, self.context))
        self.assertEqual(len(responses), 0)


if __name__ == "__main__":
    unittest.main()
