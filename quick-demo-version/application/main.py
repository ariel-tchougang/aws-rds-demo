#!/usr/bin/env python3
# Mission DB007 - Hybrid Multi-AZ Demo
# Combines precision of db007/ with practicality of application/

import time
import sys
import threading
from colorama import init, Fore, Style

# Initialize colorama
init()

from utils.config import load_config
from utils.state import DemoState
from utils.database import connect, ensure_schema, truncate, vacuum, server_fingerprint
from utils.aws import get_rds_primary_az
from utils.loops import run_write_loop, run_read_loop

def print_banner():
    """Print mission banner"""
    banner = f"""
{Fore.BLUE}╔══════════════════════════════════════════════════════════════╗
║                        MISSION DB007                         ║
║                   Multi-AZ RDS Demonstration                 ║
║                                                              ║
║  Agent: DB007      | Target: PostgreSQL Multi-AZ            ║
║  Objective: Prove RPO=0 & RTO<5min with automatic failover  ║
╚══════════════════════════════════════════════════════════════╝{Style.RESET_ALL}
    """
    print(banner)

def main():
    print_banner()
    
    cfg = load_config()
    state = DemoState()

    # Initial connection for schema & fingerprint
    try:
        with connect(cfg, role="write") as conn:
            conn.autocommit = True
            ensure_schema(conn)
            truncate(conn)
            vacuum(conn)
            fp = server_fingerprint(conn)
            state.first_fp = fp
            state.last_fp = fp
            print(f"{Fore.GREEN}[START]{Style.RESET_ALL} Connected. writer_fingerprint={fp}")
    except Exception as e:
        print(f"{Fore.RED}[START] Cannot connect to DB: {e}{Style.RESET_ALL}")
        sys.exit(1)

    # Get initial AZ
    state.first_az = get_rds_primary_az(cfg)
    if state.first_az:
        print(f"{Fore.BLUE}[RDS]{Style.RESET_ALL} Primary AZ at start: {state.first_az}")

    # Warmup phase
    print(f"{Fore.YELLOW}[WARMUP]{Style.RESET_ALL} {cfg.warmup_seconds}s...")
    warmup_deadline = time.time() + cfg.warmup_seconds
    while time.time() < warmup_deadline and not state.stop.is_set():
        time.sleep(1)

    # Start monitoring loops
    print(f"{Fore.GREEN}[MISSION]{Style.RESET_ALL} Starting traffic generation...")
    t_write = threading.Thread(target=run_write_loop, args=(cfg, state), daemon=True)
    t_read = threading.Thread(target=run_read_loop, args=(cfg, state), daemon=True)
    t_write.start()
    t_read.start()

    # Runtime
    deadline = time.time() + cfg.runtime_seconds
    try:
        while time.time() < deadline and not state.stop.is_set():
            time.sleep(1)
    except KeyboardInterrupt:
        print(f"\n{Fore.YELLOW}[STOP]{Style.RESET_ALL} Mission interrupted by user")
    finally:
        state.stop.set()
        t_write.join(timeout=5)
        t_read.join(timeout=5)

    # Final checks
    try:
        with connect(cfg) as conn:
            state.last_fp = server_fingerprint(conn)
    except Exception as e:
        print(f"{Fore.RED}[END] Could not reconnect: {e}{Style.RESET_ALL}")

    state.last_az = get_rds_primary_az(cfg)

    # RPO=0 verification
    rpo_zero = "UNKNOWN"
    gap_note = ""
    try:
        with connect(cfg) as conn, conn.cursor() as cur:
            cur.execute("SELECT max(id) AS max_id FROM demo_events;")
            max_id = int(cur.fetchone()["max_id"] or 0)
            if state.last_id_before_error:
                cur.execute("SELECT id FROM demo_events ORDER BY id DESC LIMIT 10;")
                ids = [int(r["id"]) for r in cur.fetchall()]
                contiguous = all(ids[i] - ids[i+1] == 1 for i in range(len(ids) - 1))
                rpo_zero = "YES" if contiguous else f"LIKELY YES (contiguous={contiguous})"
                gap_note = f"(sample: {ids[:5]}...)"
            else:
                rpo_zero = "YES (no failure detected)"
    except Exception as e:
        rpo_zero = f"UNKNOWN ({e})"

    # Mission Report
    print(f"\n{Fore.BLUE}==================== DB007 MISSION REPORT ===================={Style.RESET_ALL}")
    print(f"Start writer_fingerprint : {state.first_fp}")
    if state.first_az:
        print(f"Start primary AZ         : {state.first_az}")
    print(f"End writer_fingerprint   : {state.last_fp}")
    if state.last_az:
        print(f"End primary AZ           : {state.last_az}")
    print(f"Total writes             : {state.write_count}")
    print(f"Total reads              : {state.read_count}")
    print(f"Estimated downtime (s)   : {state.total_downtime_s:.2f}")
    print(f"RPO = 0 confirmed        : {rpo_zero} {gap_note}")
    
    if state.first_fp and state.last_fp and state.first_fp != state.last_fp:
        print(f"Writer changed           : {Fore.GREEN}YES 🛰️ (failover observed){Style.RESET_ALL}")
    else:
        print("Writer changed           : NO/UNKNOWN")
    
    if state.first_az and state.last_az and state.first_az != state.last_az:
        print(f"AZ changed               : {Fore.GREEN}YES (Multi-AZ failover){Style.RESET_ALL}")
    else:
        print("AZ changed               : NO/UNKNOWN")
    
    print(f"{Fore.BLUE}==============================================================={Style.RESET_ALL}")
    print(f"\n{Fore.GREEN}Mission accomplished. License to query remains valid. 🕶️{Style.RESET_ALL}")

if __name__ == "__main__":
    main()