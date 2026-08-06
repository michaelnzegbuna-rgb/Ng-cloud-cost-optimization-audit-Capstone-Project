# Cloud Cost Optimization Audit
### Rightsizing Azure Cloud Spend for Nigerian Startups

An individual audit project built entirely on **Microsoft Azure's native, no-cost tools**
(Portal GUI, Azure Monitor, Azure Advisor, Cost Management + Billing). It deploys a
sample "startup-like" environment that mirrors common over-provisioning mistakes,
audits it, rightsizes it, and documents the before/after savings.

> 📄 Full written report: [`docs/Cloud-Cost-Optimization-Audit.pdf`](docs/Cloud-Cost-Optimization-Audit.pdf) · [`docs/Cloud-Cost-Optimization-Audit.docx`](docs/Cloud-Cost-Optimization-Audit.docx)
> 🖼️ Step-by-step screenshots and explanations: [`STEPS.md`](STEPS.md)

---

## 1. The Problem

Nigerian tech startups — fintech, e-commerce, logistics, and beyond — increasingly
build on cloud infrastructure to scale quickly. But cloud bills are charged in **US
Dollars**, and with naira volatility, even modest over-provisioning becomes a painful,
unpredictable expense for founders on a tight runway.

Common patterns seen across early-stage Nigerian startups:

- Provisioning "just in case" — VMs and databases sized for hoped-for scale, not actual usage
- Leaving staging/test environments running 24/7 on production-grade pricing tiers
- Forgetting to delete unattached disks, unused public IPs, and old snapshots
- Storing logs, backups, and cold data in expensive "Hot" storage tiers indefinitely
- No one actively reviewing the cloud bill until it becomes an emergency

For a startup spending **$500–$2,000/month**, a rightsizing audit can typically cut
**30–60%** of the bill with no loss of performance or reliability.

## 2. What This Project Delivers (MVP)

| Feature | Description |
|---|---|
| **Usage Review** | Pull real utilization metrics (CPU, memory, DTU, storage access) via Azure Monitor and Azure Advisor |
| **Cost-Saving Recommendations** | Prioritized rightsizing actions (VM resize, storage tier changes, orphan cleanup, reserved capacity, auto-shutdown) |
| **Before-and-After Comparison** | Deploy a baseline ("before") and optimized ("after") environment and compare actual/estimated cost side-by-side |
| **Audit Report** | Structured report documenting findings, recommendations, and projected savings |

## 3. Architecture

Simplified Nigerian startup stack (e.g. fintech / e-commerce MVP), deployed in a
single resource group: `rg-cost-audit-demo`.

- Users reach a **Web App** (App Service) over HTTPS
- The Web App calls a background-processing **Virtual Machine** for worker/batch jobs
- Both read/write to an **Azure SQL Database**
- Logs, backups, and uploaded files sit in a **Storage Account**
- Supporting networking: **Virtual Network**, **Network Interface**, **Public IP**

### Before → After

| # | Resource | Before | After | Savings |
|---|---|---|---|---|
| 1 | Virtual Machine | Standard_D4s_v3, Premium SSD — $140/mo | Standard_B2s, Standard SSD, auto-shutdown 10pm–6am — $32/mo | **77%** |
| 2 | App Service Plan | P1v2, running 24/7 — $146/mo | B1 (Basic) — $13/mo | **91%** |
| 3 | Azure SQL Database | S3 Standard (100 DTU) — $150/mo | Serverless GP_S_Gen5_1, auto-pause 60min — $25/mo | **83%** |
| 4 | Storage Account | All data in Hot tier — $25/mo | Lifecycle: Hot → Cool (30d) → Archive (90d) — $9/mo | **64%** |
| 5 | Orphaned disk + IP | Leftover, unused — $9/mo | Deleted — $0/mo | **100%** |
| **Total** | | **≈$470/mo** | **≈$79/mo** | **≈83%** |

*Sample figures are illustrative (Azure pay-as-you-go list pricing). Replace with your
actual Cost Management export for a real audit, and convert to Naira at the prevailing
exchange rate for local context.*

## 4. Repository Structure

```
.
├── README.md                 # this file
├── STEPS.md                  # step-by-step walkthrough with screenshots + explanations
├── infra/
│   ├── main-before.bicep     # deploys the over-provisioned baseline environment
│   └── main-after.bicep      # deploys the rightsized environment
├── scripts/
│   ├── 01-deploy-before.sh
│   ├── 02-cleanup-orphans.sh
│   ├── 03-get-advisor-recommendations.sh
│   ├── 04-deploy-after.sh
│   └── storage-lifecycle-policy.json
├── docs/
│   ├── Cloud-Cost-Optimization-Audit.docx   # original audit report (Word)
│   └── Cloud-Cost-Optimization-Audit.pdf    # same report, PDF
└── screenshots/
    └── README.md              # naming convention + list of screenshots to capture
```

## 5. Quick Start

```bash
git clone <this-repo-url>
cd cloud-cost-optimization-audit

# 1. Deploy the deliberately over-provisioned baseline
./scripts/01-deploy-before.sh

# 2. Let it run 24-48h (ideally 7-14 days) under light traffic so
#    Azure Monitor / Advisor collect telemetry, then review the portal
#    (see STEPS.md, Steps 3-5) and capture your screenshots.

# 3. Clean up orphaned resources found along the way
./scripts/02-cleanup-orphans.sh

# 4. Export Advisor's cost recommendations
./scripts/03-get-advisor-recommendations.sh

# 5. Deploy the rightsized environment
./scripts/04-deploy-after.sh
```

Requires the [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) and
an active Azure subscription (free-tier / pay-as-you-go both work).

## 6. Deliverables Checklist

- [ ] Deployed resource group `rg-cost-audit-demo` (before and/or after state)
- [ ] IaC files — `main-before.bicep`, `main-after.bicep`, deployment scripts
- [ ] Architecture & cost note (Section 3 above)
- [ ] 2–3 minute demo video
- [ ] Completed audit report (`docs/Cloud-Cost-Optimization-Audit.docx` / `.pdf`)
- [ ] Screenshots for every step (see [`screenshots/README.md`](screenshots/README.md))

## License

MIT — see [LICENSE](LICENSE).
