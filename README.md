# Cloud Cost Optimization Audit  
**Rightsizing Azure Cloud Spend for Nigerian Startups**

---

## 📌 Project Overview
This project demonstrates how Nigerian startups can reduce Azure cloud costs by 30–60% through rightsizing and proactive cost governance. It deploys a deliberately over‑provisioned environment, audits usage with Azure native tools, and applies optimizations to achieve significant savings.

- **Platform:** Microsoft Azure (Portal / GUI)  
- **Project Type:** Individual Project Work  
- **Region:** South Africa North (closest full-service Azure region to Nigeria)  

---

## 🇳🇬 Nigerian Context
Startups in Nigeria face unique challenges:
- Cloud bills are charged in USD, while naira volatility magnifies costs.
- Common mistakes include oversized VMs, premium tiers for low traffic, orphaned resources, and expensive storage tiers.
- Even modest spend ($500–$2,000/month) can be cut by **30–60%** with a rightsizing audit.

---

## ⚙️ Architecture

### Baseline (Before) – Over‑Provisioned
- **VM:** Standard_D4s_v3 (4 vCPU / 16GB), Premium SSD → <5% CPU usage  
- **App Service Plan:** P1v2 Premium → staging traffic on premium tier  
- **SQL Database:** S3 Standard (100 DTU) → far exceeds query load  
- **Storage:** All data in Hot tier → logs/backups billed at Hot rates  
- **Orphaned Resources:** Unattached disk + public IP  

### Optimized (After) – Rightsized
- **VM:** Standard_B2s (burstable, 2 vCPU/4GB), Standard SSD, auto‑shutdown 10pm–6am  
- **App Service Plan:** B1 Basic → sufficient for staging/low traffic  
- **SQL Database:** Serverless GP_S_Gen5_1, auto‑pause after 60 min  
- **Storage:** Lifecycle policy Hot → Cool (30 days) → Archive (90 days)  
- **Orphaned Resources:** Deleted  

---

## 💰 Cost Comparison

| Resource            | Before ($/mo) | After ($/mo) | Savings ($) | Savings % |
|---------------------|---------------|--------------|-------------|-----------|
| Virtual Machine     | 140           | 32           | 108         | 77%       |
| App Service Plan    | 146           | 13           | 133         | 91%       |
| SQL Database        | 150           | 25           | 125         | 83%       |
| Storage Account     | 25            | 9            | 16          | 64%       |
| Orphaned Disk + IP  | 9             | 0            | 9           | 100%      |
| **Total**           | ≈470          | ≈79          | ≈391        | ≈83%      |

---

## 🛠️ Step‑by‑Step Implementation (Azure Portal / GUI)

1. **Create Resource Group** → `rg-cost-audit-demo`  
2. **Deploy Baseline Environment** (VM, App Service, SQL DB, Storage, orphaned resources)  
3. **Review Usage** with Azure Monitor (CPU, DTU, storage access patterns)  
4. **Pull Recommendations** from Azure Advisor (rightsizing, cleanup, reserved instances)  
5. **Review Cost Analysis** in Cost Management + Billing  
6. **Apply Rightsizing** (resize VM, downgrade App Service, switch SQL to serverless, delete orphans, apply lifecycle policy)  
7. **Re‑measure Costs** and compare before/after  
8. **Export Audit Report** with findings, screenshots, and savings  

---

## 📜 Infrastructure‑as‑Code (IaC)

Scripts and templates provided in `/infra` and `/scripts`:
- `01-deploy-before.sh` → deploy baseline (`main-before.bicep`)  
- `02-cleanup-orphans.sh` → delete unused disks/IPs  
- `03-get-advisor-recommendations.sh` → export Advisor cost recommendations  
- `main-after.bicep` → deploy optimized environment  
- `storage-lifecycle-policy.json` → apply storage lifecycle rules  

---

## 📑 Audit Report Template
- **Executive Summary:** Monthly spend before/after, % savings  
- **Scope:** Resources audited, methods used  
- **Findings:** Utilization metrics + recommendations  
- **Cost Comparison:** Table of savings  
- **Future Recommendations:** Reserved Instances, Hybrid Benefit  
- **Conclusion:** Impact summary + next review date (quarterly recommended)  

---

---

## ✅ Deliverables Checklist
- [x] Deployed resource group (`rg-cost-audit-demo`)  
- [x] IaC files (`main-before.bicep`, `main-after.bicep`, scripts)  
- [x] Architecture & cost note  
- [x] 2–3 minute demo video  
- [x] Completed audit report  

---

## 🔑 Key Takeaway
By leveraging **Azure Monitor, Advisor, and Cost Management**, Nigerian startups can **cut cloud spend by up to 83%** without sacrificing performance — extending runway and freeing capital for growth.

