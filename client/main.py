"""
gRPC Client - Cumulus
Run this file from the repo root: python -m client.main
(Make sure the server is running first: python -m server.main)
"""

import grpc
import logging
import os
import platform

from dotenv import load_dotenv

import cumulus_pb2
import cumulus_pb2_grpc
from client.db import initialize as init_db
from client.scanner import scan
from client.uploader import upload_all
from common.network import get_local_ip, get_hostname

load_dotenv()

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
logger = logging.getLogger(__name__)

SERVER_IP   = os.environ.get("SERVER_IP", "127.0.0.1")
SERVER_PORT = int(os.environ.get("SERVER_PORT", 50051))
BACKUP_DIR  = os.environ.get("BACKUP_DIR", "")


def register(stub: cumulus_pb2_grpc.RegistrationStub):
    hostname    = get_hostname()
    ip_address  = get_local_ip()
    os_platform = f"{platform.system()} {platform.release()}"

    response = stub.Register(cumulus_pb2.RegisterRequest(
        hostname=hostname,
        ip_address=ip_address,
        os_platform=os_platform,
    ))
    if response.success:
        logger.info(f"Registered: {response.message}")
    else:
        logger.error(f"Registration failed: {response.message}")


def run():
    if not BACKUP_DIR:
        logger.error("BACKUP_DIR is not set in .env")
        return

    init_db()

    logger.info(f"Scanning backup directory: {BACKUP_DIR}")
    queued = scan(BACKUP_DIR)

    if queued == 0:
        logger.info("Nothing to upload.")
        return

    server_address = f"{SERVER_IP}:{SERVER_PORT}"
    logger.info(f"Connecting to server at {server_address}...")

    with grpc.insecure_channel(server_address) as channel:
        register(cumulus_pb2_grpc.RegistrationStub(channel))
        upload_all(cumulus_pb2_grpc.BackupStub(channel))


if __name__ == "__main__":
    run()
