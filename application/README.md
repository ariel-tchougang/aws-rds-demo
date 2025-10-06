# Mission DB007 - Hybrid Multi-AZ Demo

**Solution hybride** combinant la précision de `db007/` avec la praticité de `application/`.

## 🎯 Objectifs

- **RPO = 0** : Vérification de continuité des données
- **RTO < 2 minutes** : Mesure précise du temps de récupération  
- **Détection automatique** : Server fingerprint + AZ tracking
- **Interface colorée** : Feedback visuel en temps réel

## 🚀 Quick Start

### 1. Setup Environment

```bash
# Upload demo/ folder to ~/demo/ on EC2/Cloud9
cd ~/demo
./scripts/setup.sh
```

### 2. Configure

```bash
# Edit with your RDS details
nano .env
```

### 3. Start Mission

```bash
# Activate aliases
source ~/.bashrc

# Start demo
demo-start
```

### 4. Trigger Failover

```bash
# In another terminal
demo-failover
```

## 📊 Features

### From db007/
- ✅ **Psycopg3** : Performance moderne
- ✅ **Server fingerprint** : Détection précise du failover
- ✅ **RPO=0 verification** : Analyse de continuité des IDs
- ✅ **RTO measurement** : Timing exact du downtime
- ✅ **Threading efficace** : Read/write loops séparés

### From application/
- ✅ **Interface colorée** : Colorama pour le feedback visuel
- ✅ **Scripts pratiques** : Setup, status, failover
- ✅ **Configuration .env** : Simple et flexible
- ✅ **Aliases bash** : Commandes courtes

## 🔧 Configuration

```bash
# Database (REQUIRED)
DB_HOST=your-rds-endpoint.region.rds.amazonaws.com
DB_PORT=5432
DB_NAME=datacorp
DB_USER=db007
DB_PASSWORD=your-password

# Mission Parameters (Optional)
WARMUP_SECONDS=20
RUNTIME_SECONDS=600
WRITE_QPS=5.0
READ_QPS=2.0

# AWS (Optional - for AZ tracking)
AWS_REGION=us-east-1
RDS_INSTANCE_ID=db007-mission-postgres
```

## 📈 Output Example

```
[START] Connected. writer_fingerprint=10.0.10.123:5432 pg15.4@db007-mission-postgres.xyz.rds.amazonaws.com
[RDS] Primary AZ at start: us-east-1a
[WARMUP] 20s...
[MISSION] Starting traffic generation...
[HEALTH] writes=5 reads=2 count=5 last_id=5 last_fp=10.0.10.123:5432... latency_ms=12.3
[WRITE] FAILOVER DETECTED ⚠️ connection lost
[RECOVERY] WRITE RESUMED ✅ after 67.45s

==================== DB007 MISSION REPORT ====================
Start writer_fingerprint : 10.0.10.123:5432 pg15.4@db007-mission-postgres.xyz.rds.amazonaws.com
Start primary AZ         : us-east-1a
End writer_fingerprint   : 10.0.11.234:5432 pg15.4@db007-mission-postgres.xyz.rds.amazonaws.com
End primary AZ           : us-east-1b
Total writes             : 1247
Total reads              : 623
Estimated downtime (s)   : 67.45
RPO = 0 confirmed        : YES (sample: [1247, 1246, 1245, 1244, 1243]...)
Writer changed           : YES 🛰️ (failover observed)
AZ changed               : YES (Multi-AZ failover)
===============================================================

Mission accomplished. License to query remains valid. 🕶️
```

## 🎮 Convenience Aliases

- `demo-activate` : Active l'environnement Python
- `demo-start` : Lance la démonstration
- `demo-status` : Vérifie le statut RDS
- `demo-failover` : Déclenche un failover contrôlé

## 📦 Dependencies

- **psycopg[binary]>=3.1.0** : PostgreSQL moderne
- **boto3>=1.26.0** : AWS SDK (optionnel)
- **colorama>=0.4.4** : Interface colorée
- **python-dotenv>=1.0.0** : Configuration .env

---

**Mission DB007** - *Elite Database Resilience Demonstration* 🕶️