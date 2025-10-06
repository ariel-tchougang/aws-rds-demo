from typing import Optional
from .config import Config

try:
    import boto3
except ImportError:
    boto3 = None

def get_rds_primary_az(cfg: Config) -> Optional[str]:
    """Get current primary AZ for RDS instance"""
    if not (cfg.aws_region and cfg.rds_instance_id and boto3):
        return None
    
    try:
        rds = boto3.client("rds", region_name=cfg.aws_region)
        resp = rds.describe_db_instances(DBInstanceIdentifier=cfg.rds_instance_id)
        dbi = resp["DBInstances"][0]
        return dbi.get("AvailabilityZone")
    except Exception as e:
        print(f"[RDS] Could not fetch AZ: {e}")
        return None