"""
Common network utilities shared between client and server.
"""

import socket
import logging

logger = logging.getLogger(__name__)


def get_local_ip() -> str:
    """Resolve the local IP address used to reach external networks."""
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
            s.connect(("8.8.8.8", 80))
            return s.getsockname()[0]
    except Exception as e:
        logger.warning(f"Could not determine local IP address: {e}")
        return "127.0.0.1"


def get_hostname() -> str:
    """Return the machine's hostname."""
    return socket.gethostname()
