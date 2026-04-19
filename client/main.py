"""
gRPC Client - Cumulus
Run this file from the repo root: python -m client.main
(Make sure the server is running first: python -m server.main)
"""

import os
import dotenv
import grpc
import logging
import platform
import socket
import cumulus_pb2
import cumulus_pb2_grpc
from common.network import get_local_ip, get_hostname

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
logger = logging.getLogger(__name__)

dotenv.load_dotenv()
IP = os.environ.get("SERVER_IP", '127.0.0.1')
PORT = int(os.environ.get("SERVER_PORT", 50051))
SERVER_ADDRESS = f"{IP}:{PORT}"

def register():
    hostname = get_hostname()
    ip_address = get_local_ip()
    os_platform = f"{platform.system()} {platform.release()}"

    logger.info(f"Registering with server at {SERVER_ADDRESS}...")
    logger.info(f"  Hostname:    {hostname}")
    logger.info(f"  IP Address:  {ip_address}")
    logger.info(f"  OS/Platform: {os_platform}")

    with grpc.insecure_channel(SERVER_ADDRESS) as channel:
        stub = cumulus_pb2_grpc.RegistrationStub(channel)
        response = stub.Register(cumulus_pb2.RegisterRequest(
            hostname=hostname,
            ip_address=ip_address,
            os_platform=os_platform,
        ))

    if response.success:
        logger.info(f"Registration successful: {response.message}")
    else:
        logger.error(f"Registration failed: {response.message}")


if __name__ == "__main__":
    register()
