from dataclasses import dataclass, field
from typing import Optional
import threading

@dataclass
class DemoState:
    """Shared state for Mission DB007 monitoring"""
    # Control
    stop: threading.Event = field(default_factory=threading.Event)
    
    # Counters
    write_count: int = 0
    read_count: int = 0
    last_id: int = 0
    
    # Performance metrics
    last_latency_ms: float = 0.0
    
    # Failover tracking
    fail_started_at: Optional[float] = None
    total_downtime_s: float = 0.0
    last_id_before_error: Optional[int] = None
    
    # Server fingerprints (for failover detection)
    first_fp: Optional[str] = None
    last_fp: Optional[str] = None
    
    # Availability zones
    first_az: Optional[str] = None
    last_az: Optional[str] = None