from typing import Optional
import psycopg
from psycopg.rows import dict_row

from .config import Config

def connect(cfg: Config, *, role: str = "write"):  # role: "write" | "read"
    """Create database connection with proper configuration"""
    tsa = "read-write" if role == "write" else "any"  # or "read-only" if using a reader endpoint
    dsn = (
        f"host={cfg.db_host} port={cfg.db_port} dbname={cfg.db_name} user={cfg.db_user} password={cfg.db_password} "
        f"sslmode=require connect_timeout=5 target_session_attrs={tsa} "
        f"options='-c statement_timeout=3000 -c lock_timeout=3000 -c idle_in_transaction_session_timeout=3000'"
    )
    return psycopg.connect(dsn, row_factory=dict_row)

# def connect(cfg: Config):
#     """Create database connection with proper configuration"""
#     dsn = (
#         f"host={cfg.db_host} port={cfg.db_port} "
#         f"dbname={cfg.db_name} user={cfg.db_user} password={cfg.db_password} "
#         f"sslmode=require connect_timeout=5 "
#         f"target_session_attrs=read-write "
#         f"options='-c statement_timeout=3000 "
#         f"-c lock_timeout=3000 "
#         f"-c idle_in_transaction_session_timeout=3000'"
#     )
#     return psycopg.connect(dsn, row_factory=dict_row)

def ensure_schema(conn):
    """Create demo table if it doesn't exist"""
    with conn.cursor() as cur:
        cur.execute("""
        CREATE TABLE IF NOT EXISTS demo_events (
          id BIGSERIAL PRIMARY KEY,
          payload TEXT NOT NULL,
          ts_insert TIMESTAMPTZ NOT NULL DEFAULT now(),
          writer_fingerprint TEXT NOT NULL
        );
        """)

def truncate(conn):
    with conn.cursor() as cur:
        cur.execute("TRUNCATE demo_events RESTART IDENTITY;")

def vacuum(conn):
    with conn.cursor() as cur:
        cur.execute("VACUUM FULL demo_events;")

def server_fingerprint(conn) -> str:
    """Get unique server fingerprint for failover detection"""
    with conn.cursor() as cur:
        cur.execute("SELECT inet_server_addr()::text AS ip, inet_server_port() AS port, version() AS ver;")
        row = cur.fetchone()
        ip = row["ip"] or "unknown-ip"
        port = row["port"] or "unknown-port"
        ver = row["ver"].split()[1] if row and row["ver"] else "unknown-ver"
        return f"{ip}:{port} pg{ver}@{conn.info.host}"