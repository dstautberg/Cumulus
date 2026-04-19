import grpc
import logging

import cumulus_pb2
import cumulus_pb2_grpc
from server.db import get_connection

logger = logging.getLogger(__name__)


class RegistrationServicer(cumulus_pb2_grpc.RegistrationServicer):
    """Implements the Registration gRPC service."""

    def Register(self, request: cumulus_pb2.RegisterRequest, context: grpc.ServicerContext) -> cumulus_pb2.RegisterReply:
        """Upsert the client record, updating last_seen on re-registration."""
        hostname = request.hostname.strip()
        ip_address = request.ip_address.strip()
        os_platform = request.os_platform.strip()

        if not hostname or not ip_address or not os_platform:
            context.set_code(grpc.StatusCode.INVALID_ARGUMENT)
            context.set_details("hostname, ip_address, and os_platform are all required.")
            return cumulus_pb2.RegisterReply(success=False, message="Missing required fields.")

        try:
            with get_connection() as conn:
                conn.execute("""
                    INSERT INTO clients (hostname, ip_address, os_platform, first_seen, last_seen)
                    VALUES (?, ?, ?, datetime('now'), datetime('now'))
                    ON CONFLICT(hostname) DO UPDATE SET
                        ip_address  = excluded.ip_address,
                        os_platform = excluded.os_platform,
                        last_seen   = datetime('now')
                """, (hostname, ip_address, os_platform))
                conn.commit()

            logger.info(f"Registered client: hostname={hostname}, ip={ip_address}, os={os_platform}")
            return cumulus_pb2.RegisterReply(success=True, message=f"Client '{hostname}' registered successfully.")

        except Exception as e:
            logger.error(f"Failed to register client '{hostname}': {e}")
            context.set_code(grpc.StatusCode.INTERNAL)
            context.set_details("Internal server error during registration.")
            return cumulus_pb2.RegisterReply(success=False, message="Registration failed.")
