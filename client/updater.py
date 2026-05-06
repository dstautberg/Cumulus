"""
client/updater.py

Self-update via git pull + restart.

Usage: create one idle_event per worker thread, pass them all to
start_update_thread(). When every event is set the workers are sleeping
and it's safe to restart.
"""

import logging
import os
import subprocess
import sys
import threading
import time

logger = logging.getLogger(__name__)

# How often to check for updates (seconds). Stagger it so it doesn't
# coincide with the backup/restore wakeup on every cycle.
UPDATE_CHECK_INTERVAL = 900  # 15 minutes


def _git(args: list[str]) -> subprocess.CompletedProcess:
    """Run a git command in the repo root (parent of this file's package)."""
    repo_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    return subprocess.run(
        ["git"] + args,
        cwd=repo_root,
        capture_output=True,
        text=True,
    )


def _update_available() -> bool:
    """Return True if origin/master is ahead of HEAD."""
    fetch = _git(["fetch", "origin", "master"])
    if fetch.returncode != 0:
        logger.warning(f"[updater] git fetch failed: {fetch.stderr.strip()}")
        return False

    behind = _git(["rev-list", "HEAD..origin/master", "--count"])
    if behind.returncode != 0:
        logger.warning(f"[updater] git rev-list failed: {behind.stderr.strip()}")
        return False

    count = int(behind.stdout.strip() or "0")
    if count > 0:
        logger.info(f"[updater] {count} new commit(s) available on origin/master.")
    return count > 0


def _apply_update() -> None:
    """Pull latest commits and restart the process."""
    logger.info("[updater] Applying update — running git pull...")
    pull = _git(["pull", "origin", "master"])
    if pull.returncode != 0:
        logger.error(f"[updater] git pull failed:\n{pull.stderr.strip()}")
        return

    logger.info("[updater] Pull succeeded. Restarting process now.")
    # Replace this process with a fresh interpreter running the same command.
    os.execv(sys.executable, [sys.executable] + sys.argv)


def _update_loop(idle_events: list[threading.Event]) -> None:
    """
    Periodically check for updates. When one is available, wait until
    every worker is idle (its idle_event is set) before restarting.
    """
    # Stagger the first check so startup traffic has settled.
    time.sleep(60)

    while True:
        try:
            if _update_available():
                logger.info("[updater] Waiting for workers to be idle before restarting...")
                # Block until every worker signals it's sleeping.
                for event in idle_events:
                    event.wait()
                _apply_update()
                # If _apply_update returns (e.g. pull failed), wait a full
                # interval before trying again.
        except Exception as e:
            logger.error(f"[updater] Unexpected error: {e}")

        time.sleep(UPDATE_CHECK_INTERVAL)


def start_update_thread(idle_events: list[threading.Event]) -> threading.Thread:
    """
    Spawn and return the updater daemon thread.

    idle_events: one threading.Event per worker thread. Each worker should
                 call event.set() when it goes to sleep and event.clear()
                 when it wakes up to do work.
    """
    t = threading.Thread(
        target=_update_loop,
        args=(idle_events,),
        name="updater",
        daemon=True,
    )
    t.start()
    logger.info("[updater] Update thread started.")
    return t
