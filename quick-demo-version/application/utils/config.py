from dataclasses import dataclass
from typing import Optional
import os
import sys
from dotenv import load_dotenv

# Load .env file automatically
load_dotenv()

def _env(name: str, default=None, cast=None):
    """Get environment variable with optional casting"""
    v = os.getenv(name, default)
    if v is None:
        return None
    return cast(v) if cast else v

@dataclass
class Config:
    """Configuration for Mission DB007"""
    # Database connection
    db_host: str
    db_port: int
    db_name: str
    db_user: str
    db_password: str

    # Mission parameters
    warmup_seconds: int = 20
    runtime_seconds: int = 360
    write_qps: float = 5.0
    read_qps: float = 2.0
    
    # Retry configuration
    retry_max: int = 0           # 0 = unlimited
    retry_backoff: float = 0.5   # seconds
    backoff_cap: float = 8.0     # seconds

    # AWS configuration (optional)
    aws_region: Optional[str] = None
    rds_instance_id: Optional[str] = None

def load_config() -> Config:
    """Load configuration from environment variables"""
    required = ["DB_HOST", "DB_PORT", "DB_NAME", "DB_USER", "DB_PASSWORD"]
    missing = [k for k in required if not os.getenv(k)]
    if missing:
        print(f"[CONFIG] Missing required env vars: {', '.join(missing)}")
        sys.exit(2)

    return Config(
        db_host=_env("DB_HOST"),
        db_port=_env("DB_PORT", cast=int),
        db_name=_env("DB_NAME"),
        db_user=_env("DB_USER"),
        db_password=_env("DB_PASSWORD"),
        warmup_seconds=_env("WARMUP_SECONDS", 20, int),
        runtime_seconds=_env("RUNTIME_SECONDS", 600, int),
        write_qps=_env("WRITE_QPS", 5.0, float),
        read_qps=_env("READ_QPS", 2.0, float),
        retry_max=_env("RETRY_MAX", 0, int),
        retry_backoff=_env("RETRY_BACKOFF", 0.5, float),
        backoff_cap=_env("BACKOFF_CAP", 8.0, float),
        aws_region=_env("AWS_REGION"),
        rds_instance_id=_env("RDS_INSTANCE_ID"),
    )