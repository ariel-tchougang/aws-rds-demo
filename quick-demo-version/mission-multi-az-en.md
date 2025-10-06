# Mission Multi-AZ: DB007 Operation

> 🏠 **Return to:** [Main README](README.md) | [Brief Français](mission-multi-az-fr.md)

**Context**  
Agent **DB007**, elite IT consultant, has been mandated by **DataCorp**.  
Their challenge: how to guarantee **business continuity** for their critical database in the face of failures, AZ outages, or local disasters?  

The mission: demonstrate that with AWS RDS in **Multi-AZ deployment**, their data and operations survive unexpected events, achieving **RPO = 0** and a **minimal RTO**.  

---

## Mission Steps

### 1. Setting up the operation field
- Deploy a **VPC across two Availability Zones (AZs)**.  
- **Quick Demo**: Two public subnets for both application and RDS (simplified setup).  

### 2. Activating the digital vault
- Launch an **RDS PostgreSQL (or MySQL)** instance in **Multi-AZ** mode.  
- AWS automatically creates a **synchronous standby replica** in the second AZ.  

### 3. Simulating enemy activity
- Run the DB007 agent **directly from your PC or CloudShell**.  
- Generates continuous **INSERT** and **SELECT** operations with timestamps.  

### 4. Reconnaissance
- Query the database:  
  - The **primary** is hosted in **AZ1**.  
  - The **standby** waits in **AZ2**, ready to take over.  

### 5. Controlled sabotage
- Trigger a **reboot with failover**: simulating an unexpected AZ1 outage.  

### 6. Turbulence zone
- Database traffic halts briefly.  
- Applications experience a short interruption, but **no corruption** occurs.  

### 7. Rapid reorganization
- The standby is promoted as the new **primary** in AZ2.  
- Traffic automatically resumes.  

### 8. Proof of resilience
- Data written just before the failover is still present.  
- Demonstration of **RPO = 0** and **RTO of a few seconds**.  

### 9. New order established
- Confirm status:  
  - **Primary → AZ2**  
  - **Standby → recreated in AZ1**  
- DataCorp can now rest easy: their database is **protected by design**.  

---

## Mission Report
> *"Mission accomplished. Thanks to AWS RDS Multi-AZ, DataCorp can survive even the trickiest outages... and DB007 keeps his license to query."* 🕶️

---

📚 **For technical implementation:** See the [main README](README.md) for quick deployment (5 minutes setup).
