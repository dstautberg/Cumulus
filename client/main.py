"""
gRPC Client - Cumulus
Run this file from the repo root: python -m client.main

Runs two background threads continuously:
  - Backup thread:  scans BACKUP_DIR and uploads changed files
  - Restore thread: polls server and downloads available files to RESTORE_DIR

Either thread is skipped if its corresponding directory is not set in .env.
"""

import grpc
import logging
import os
import platform
import threading
import time

from dotenv import load_dotenv

import cumulus_pb2
import cumulus_pb2_grpc
from client.db import initialize as init_db
from client.scanner import scan
from client.uploader import upload_all
from client.downloader import download_all
from common.network import get_local_ip, get_hostname

load_dotenv()

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
logger = logging.getLogger(__name__)

SERVER_IP    = os.environ.get("SERVER_IP", "127.0.0.1")
SERVER_PORT  = int(os.environ.get("SERVER_PORT", 50051))
BACKUP_DIR   = os.environ.get("BACKUP_DIR", "")
RESTORE_DIR  = os.environ.get("RESTORE_DIR", "")
INTERVAL_MIN = int(os.environ.get("BACKUP_INTERVAL_MINUTES", 15))
SERVER_ADDRESS = f"{SERVER_IP}:{SERVER_PORT}"


def register():
    """Register this client with the server."""
    with grpc.insecure_channel(SERVER_ADDRESS) as channel:
        stub = cumulus_pb2_grpc.RegistrationStub(channel)
        response = stub.Register(cumulus_pb2.RegisterRequest(
            hostname=get_hostname(),
            ip_address=get_local_ip(),
            os_platform=f"{platform.system()} {platform.release()}",
        ))
        if response.success:
            logger.info(f"Registered: {response.message}")
        else:
            logger.error(f"Registration failed: {response.message}")


def backup_loop():
    """Continuously scan and upload changed files."""
    logger.info(f"[backup] Starting — scanning '{BACKUP_DIR}' every {INTERVAL_MIN} min.")
    while True:
        try:
            logger.info(f"[backup] Scanning: {BACKUP_DIR}")
            queued = scan(BACKUP_DIR)
            if queued > 0:
                with grpc.insecure_channel(SERVER_ADDRESS) as channel:
                    upload_all(cumulus_pb2_grpc.BackupStub(channel))
            else:
                logger.info("[backup] Nothing to upload.")
        except Exception as e:
            logger.error(f"[backup] Unexpected error: {e}")
        time.sleep(INTERVAL_MIN * 60)


def restore_loop():
    """Continuously poll for and download available files."""
    logger.info(f"[restore] Starting — polling every {INTERVAL_MIN} min, saving to '{RESTORE_DIR}'.")
    while True:
        try:
            with grpc.insecure_channel(SERVER_ADDRESS) as channel:
                download_all(cumulus_pb2_grpc.BackupStub(channel), RESTORE_DIR)
        except Exception as e:
            logger.error(f"[restore] Unexpected error: {e}")
        time.sleep(INTERVAL_MIN * 60)


def run():
    init_db()
    register()

    threads = []

    if BACKUP_DIR:
        t = threading.Thread(target=backup_loop, name="backup", daemon=True)
        threads.append(t)
    else:
        logger.info("BACKUP_DIR not set — backup thread will not start.")

    if RESTORE_DIR:
        t = threading.Thread(target=restore_loop, name="restore", daemon=True)
        threads.append(t)
    else:
        logger.info("RESTORE_DIR not set — restore thread will not start.")

    if not threads:
        logger.error("Neither BACKUP_DIR nor RESTORE_DIR is set. Nothing to do.")
        return

    for t in threads:
        t.start()

    logger.info(f"Cumulus client running. Press Ctrl+C to stop.")

    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        logger.info("Shutting down.")


if __name__ == "__main__":
    run()
