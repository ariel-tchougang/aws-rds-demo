import time
import uuid
import json
import threading
from datetime import datetime, timezone
from colorama import Fore, Style

from .config import Config
from .state import DemoState
from .database import connect, server_fingerprint


# --- Watchdog helper for WRITE ------------------------------------------------
def _write_once_with_deadline(cfg: Config, state: DemoState, deadline_s: float = 2.0):
    """
    Executes an INSERT ... RETURNING in a thread and imposes a client-side timeout.
    If the timeout expires (socket blocked), the connection is closed to force an exception
    and a TimeoutError is raised to activate the upstream reconnection logic.
    """
    conn = connect(cfg, role="write")
    conn.autocommit = True

    # Current fingerprint (and refreshes the last observed fingerprint)
    current_fp = server_fingerprint(conn)
    state.last_fp = current_fp

    result = {"ok": False, "err": None, "inserted_id": None}

    def _do_write():
        try:
            with conn.cursor() as cur:
                payload = {
                    "uuid": str(uuid.uuid4()),
                    "at": datetime.now(timezone.utc).isoformat(),
                    "seq": state.write_count + 1,
                }
                # print(f"{Fore.YELLOW}[WRITE-DEBUG]{Style.RESET_ALL} Starting INSERT...")
                cur.execute(
                    "INSERT INTO demo_events(payload, writer_fingerprint) VALUES (%s, %s) RETURNING id;",
                    (json.dumps(payload), current_fp),
                )
                # print(f"{Fore.YELLOW}[WRITE-DEBUG]{Style.RESET_ALL} INSERT done, fetching result...")
                row = cur.fetchone()
                # print(f"{Fore.GREEN}[WRITE-DEBUG]{Style.RESET_ALL} Operation completed!")
                result["inserted_id"] = int(row["id"])
                result["ok"] = True
        except Exception as e:
            result["err"] = e

    t = threading.Thread(target=_do_write, daemon=True)
    t.start()
    t.join(timeout=deadline_s)

    if t.is_alive():
        # The INSERT is probably blocked at the socket level: we force a "clean" failure.
        try:
            conn.close()
        except Exception:
            pass
        # Let the thread finish now that the socket is closed
        t.join(timeout=1.0)
        raise TimeoutError(f"WRITE watchdog exceeded {deadline_s:.2f}s (socket hang)")

    # The thread has finished (success or exception)
    try:
        conn.close()
    except Exception:
        pass

    if not result["ok"]:
        # Raise the captured error to trigger retry/backoff handling
        raise result["err"]

    return result["inserted_id"]


def run_write_loop(cfg: Config, state: DemoState):
    """Write loop with failover detection and recovery timing (with watchdog)"""
    attempt = 0
    backoff = cfg.retry_backoff
    interval = 1.0 / cfg.write_qps if cfg.write_qps > 0 else 0.2

    # Permet de définir un délai via config si tu l’ajoutes plus tard
    write_deadline_s = float(getattr(cfg, "write_deadline_s", 2.0))

    while not state.stop.is_set():
        try:
            t0 = time.perf_counter()

            # --- INSERT avec watchdog (délais côté client)
            inserted_id = _write_once_with_deadline(cfg, state, deadline_s=write_deadline_s)
            state.last_id = inserted_id
            state.write_count += 1
            state.last_latency_ms = (time.perf_counter() - t0) * 1000.0

            # Recovery detection
            if state.fail_started_at is not None:
                dt = time.perf_counter() - state.fail_started_at
                state.total_downtime_s += dt
                print(f"{Fore.GREEN}[RECOVERY]{Style.RESET_ALL} WRITE RESUMED ✅ after {dt:.2f}s")
                state.fail_started_at = None
                attempt = 0  # Reset attempt counter on recovery
                backoff = cfg.retry_backoff  # Reset backoff

            # Rate limiting (interruptible)
            if interval > 0:
                sleep_left = interval - (time.perf_counter() - t0)
                if sleep_left > 0:
                    # Sleep en petits incréments pour répondre vite aux arrêts
                    while sleep_left > 0 and not state.stop.is_set():
                        chunk = min(0.1, sleep_left)
                        time.sleep(chunk)
                        sleep_left -= chunk

        except Exception as e:
            # Failover detection (ou watchdog TimeoutError)
            if state.fail_started_at is None:
                state.fail_started_at = time.perf_counter()
                state.last_id_before_error = state.last_id
                print(f"{Fore.RED}[WRITE]{Style.RESET_ALL} FAILOVER DETECTED ⚠️ {e}")
            else:
                print(f"{Fore.YELLOW}[WRITE]{Style.RESET_ALL} STILL DOWN ⚠️ {e}")

            attempt += 1
            if cfg.retry_max and attempt > cfg.retry_max:
                print(f"{Fore.RED}[WRITE] Max retries reached, stopping.{Style.RESET_ALL}")
                state.stop.set()
                return

            print(f"{Fore.YELLOW}[WRITE]{Style.RESET_ALL} RECONNECTING ⏳ backoff={backoff:.1f}s (attempt {attempt})")
            time.sleep(backoff)
            backoff = min(cfg.backoff_cap, backoff * 2 if backoff > 0 else cfg.retry_backoff)


def run_read_loop(cfg: Config, state: DemoState):
    """Read loop for health monitoring"""
    attempt = 0
    backoff = cfg.retry_backoff
    interval = 1.0 / cfg.read_qps if cfg.read_qps > 0 else 0.5

    while not state.stop.is_set():
        try:
            # Reconnect for each operation to detect failures quickly
            t0 = time.perf_counter()
            with connect(cfg, role="read") as conn:
                with conn.cursor() as cur:
                    cur.execute("SELECT count(*) AS c FROM demo_events;")
                    c = int(cur.fetchone()["c"])
                    cur.execute("SELECT id, writer_fingerprint, ts_insert FROM demo_events ORDER BY id DESC LIMIT 1;")
                    last = cur.fetchone()
                    state.read_count += 1
                    state.last_latency_ms = (time.perf_counter() - t0) * 1000.0

                    last_id = last["id"] if last else 0
                    last_fp = last["writer_fingerprint"] if last else "n/a"

                    print(
                        f"{Fore.CYAN}[HEALTH]{Style.RESET_ALL} "
                        f"writes={state.write_count} reads={state.read_count} "
                        f"count={c} last_id={last_id} last_fp={last_fp[:20]}... "
                        f"latency_ms={state.last_latency_ms:.1f}"
                    )

                    # Reset attempt counter on success
                    attempt = 0
                    backoff = cfg.retry_backoff

            # Rate limiting (interruptible)
            if interval > 0:
                sleep_left = interval - (time.perf_counter() - t0)
                if sleep_left > 0:
                    while sleep_left > 0 and not state.stop.is_set():
                        chunk = min(0.1, sleep_left)  # 100ms chunks
                        time.sleep(chunk)
                        sleep_left -= chunk

        except Exception as e:
            attempt += 1
            print(f"{Fore.YELLOW}[READ]{Style.RESET_ALL} PAUSED ⚠️ {e}")
            if cfg.retry_max and attempt > cfg.retry_max:
                print(f"{Fore.RED}[READ] Max retries reached, stopping.{Style.RESET_ALL}")
                state.stop.set()
                return

            print(f"{Fore.YELLOW}[READ]{Style.RESET_ALL} RECONNECTING ⏳ backoff={backoff:.1f}s (attempt {attempt})")
            time.sleep(backoff)
            backoff = min(cfg.backoff_cap, backoff * 2 if backoff > 0 else cfg.retry_backoff)
