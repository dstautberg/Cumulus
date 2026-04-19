"""
Unit tests for the RegistrationServicer.
Run from the repo root: python -m pytest tests/
"""

import unittest
import sqlite3
from unittest.mock import MagicMock, patch

import cumulus_pb2
from server.servicers.registration import RegistrationServicer


class TestRegistration(unittest.TestCase):

    def setUp(self):
        self.servicer = RegistrationServicer()
        self.context = MagicMock()

        # Patch get_connection to use an in-memory SQLite database
        self.conn = sqlite3.connect(":memory:")
        self.conn.row_factory = sqlite3.Row
        self.conn.execute("""
            CREATE TABLE clients (
                id            INTEGER PRIMARY KEY AUTOINCREMENT,
                hostname      TEXT NOT NULL UNIQUE,
                ip_address    TEXT NOT NULL,
                os_platform   TEXT NOT NULL,
                first_seen    TEXT NOT NULL DEFAULT (datetime('now')),
                last_seen     TEXT NOT NULL DEFAULT (datetime('now'))
            )
        """)
        self.conn.commit()
        self.patcher = patch("server.servicers.registration.get_connection", return_value=self.conn)
        self.patcher.start()

    def tearDown(self):
        self.patcher.stop()
        self.conn.close()

    def test_register_new_client(self):
        request = cumulus_pb2.RegisterRequest(
            hostname="test-host",
            ip_address="192.168.1.1",
            os_platform="Linux 5.15",
        )
        response = self.servicer.Register(request, self.context)
        self.assertTrue(response.success)
        self.assertIn("test-host", response.message)

    def test_register_updates_existing_client(self):
        request = cumulus_pb2.RegisterRequest(
            hostname="test-host",
            ip_address="192.168.1.1",
            os_platform="Linux 5.15",
        )
        self.servicer.Register(request, self.context)

        # Re-register with updated IP
        request2 = cumulus_pb2.RegisterRequest(
            hostname="test-host",
            ip_address="192.168.1.99",
            os_platform="Linux 5.15",
        )
        response = self.servicer.Register(request2, self.context)
        self.assertTrue(response.success)

        row = self.conn.execute("SELECT ip_address FROM clients WHERE hostname = 'test-host'").fetchone()
        self.assertEqual(row["ip_address"], "192.168.1.99")

    def test_register_missing_fields_returns_failure(self):
        request = cumulus_pb2.RegisterRequest(
            hostname="",
            ip_address="192.168.1.1",
            os_platform="Linux 5.15",
        )
        response = self.servicer.Register(request, self.context)
        self.assertFalse(response.success)
        self.context.set_code.assert_called_once()


if __name__ == "__main__":
    unittest.main()
