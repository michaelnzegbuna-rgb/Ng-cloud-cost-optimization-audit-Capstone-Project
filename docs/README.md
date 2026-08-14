# Cloud Cost Optimization Audit

**Capstone Project — Cloud Cost Optimization for Early-Stage Nigerian Startups**
Sample environment audited: Microsoft Azure · Resource group **Cost-Audit** · Subscription **Azure subscription 1** · Region **South Africa North**
Audit window: **August 1 – August 5, 2026** · Report date: **August 14, 2026**

---

## 1. Problem Context

Early-stage startups frequently overspend on cloud infrastructure because of unattached
(orphaned) resources, oversized compute that nobody ever rightsizes, and no habit of
regularly reviewing usage against the bill. This project demonstrates a **repeatable,
low-effort process** — manual review in the Azure Portal plus an automation script — for
catching that waste before it accumulates.

## 2. What Was Built (MVP)

| MVP Feature | Delivered as |
|---|---|
| Usage review | Section 6 of the audit report — Advisor, Cost Analysis, VM metrics, disk, and storage account review |
| Cost-saving recommendations | Section 7 of the audit report — prioritized, quantified list |
| Before-and-after comparison | Section 8 of the audit report |
| Audit report | `Cloud_Cost_Optimization_Audit_Report.docx` (this README summarizes the same findings) |
| Automation | `Audit-CloudCosts.ps1` — repeatable PowerShell script that reproduces the manual checks and can optionally remediate |
| Step-by-step walkthrough | `Step_by_Step_Guide.docx` — how to reproduce this audit yourself |

## 3. Environment Audited

| Property | Value |
|---|---|
| Subscription | Azure subscription 1 (`2e2423d7-eea6-4129-9fbc-d01ca17ced8e`) |
| Resource group | Cost-Audit |
| Region | South Africa North |
| Resources in scope | 1 VM (`vm-cost-audit-demo`), 1 unattached disk (`orphan-disk-demo`), 1 storage account (`storagecostaudit`), plus supporting networking (VNet, public IP, NIC) |
| Tools used | Azure Advisor, Cost Management + Billing, Azure Monitor (Metrics), Azure PowerShell (`Az` module) |

## 4. Key Findings

### 4.1 Azure Advisor score

| Score | Value | Detail |
|---|---|---|
| Overall Advisor score | **81%** | |
| **Cost score** | **37%** | 3 active cost recommendations, 2 active resources flagged |
| Security score | 100% | Following all security recommendations |
| Reliability score | 89% | |
| Operational excellence score | 100% | |
| Performance score | 100% | |

The Cost-Audit resource-group view of Advisor shows **1 active recommendation**
("*Review disks that are not attached to a VM and evaluate if you still need the
disks*", Medium impact) against **1 of 7 resources (14.3%)**, 0% complete.

### 4.2 Cost analysis (August 2026, month-to-date, 5 days)

| Metric | Value |
|---|---|
| Actual cost (Aug 1–5) | **$22.01** |
| Monthly budget | $20.00 |
| Budget status | **Over budget** (110% of budget, 5 days into the month) |

**By service:**

| Service | Cost | % of total |
|---|---|---|
| Storage | $17.35 | 78.8% |
| Virtual Machines | $3.53 | 16.0% |
| Virtual Network | $1.12 | 5.1% |
| Bandwidth | ~$0.01 | ~0.1% |

**By resource:**

| Resource | Cost | % of total |
|---|---|---|
| `orphan-disk-demo` | **$16.38** | **74.4%** |
| `vm-cost-audit-demo` (compute) | $3.53 | 16.0% |
| `vm-cost-audit-demo-vnet` (networking) | $0.97 | 4.4% |
| Remaining networking resources | ~$1.13 | ~5.2% |

**Region:** 100% of spend is in `za north` (South Africa North) — a single-region deployment, so there is no cross-region waste to investigate.

### 4.3 Compute (VM) utilization review — `vm-cost-audit-demo`

| Property | Value |
|---|---|
| OS | Linux — Ubuntu 22.04 LTS (Pro) |
| Size | Standard B2ls v2 (2 vCPUs, 4 GiB RAM) |
| Status at time of audit | Stopped (deallocated) |
| Auto-shutdown | **Not enabled** |
| Average CPU, trailing 7 days | **0.17%** |
| Peak CPU, trailing 7 days | ~1.6% (before the VM was stopped) |
| Public IP | 4.222.218.107 (static) |
| Created | August 3, 2026, 12:39 PM UTC |

**Observation:** sustained CPU utilization below 1% shows the VM is significantly
oversized for actual workload (idle/demo usage), and with no auto-shutdown schedule it
would keep accruing compute charges around the clock any time it's left running.

### 4.4 Storage account review — `storagecostaudit`

| Property | Value |
|---|---|
| Performance tier | Standard |
| Replication | Locally-redundant storage (LRS) |
| Account kind | StorageV2 (general purpose v2) |
| Default access tier | **Hot** |
| Public network access | Enabled (from all networks) |
| Blob / container soft delete | Enabled (7-day retention) |
| Versioning | Disabled |
| Minimum TLS version | 1.2 |
| Infrastructure (double) encryption | Disabled |

**Observation:** the account defaults to the Hot tier, which is the right choice only for
frequently-accessed data. If this becomes a store for infrequent logs/backups, moving to
Cool or Archive would meaningfully cut per-GB storage cost. Public network access open to
all networks is a security note worth flagging even though it's outside this audit's cost
scope.

### 4.5 Orphaned resource — `orphan-disk-demo` ⚠️ Highest-priority finding

| Property | Value |
|---|---|
| Disk state | **Unattached** — not managed by any VM |
| Size | 1024 GiB |
| Storage type | Premium SSD v2 (LRS) |
| Provisioned IOPS / throughput | 3,000 IOPS / 125 MB/s |
| Region | South Africa North (Zone 1) |
| Created | August 3, 2026, 3:07 PM |
| Encryption | Platform-managed key |
| **Cost impact (Aug 1–5)** | **$16.38 (74.4% of resource-group spend)** |

This disk was provisioned at 1024 GiB on the Premium SSD v2 tier — a high-performance,
high-cost tier — and has never been attached to a VM. At its observed burn rate of
roughly **$8/day**, leaving it running would cost on the order of **$240+/month
(≈ $2,900+/year)** in pure waste. **This is the single highest-priority finding in the
audit.**

## 5. Recommendations

| # | Recommendation | Priority | Estimated impact |
|---|---|---|---|
| 1 | Delete `orphan-disk-demo` (snapshot first if data must be retained) | **High** | Removes $16.38 MTD / ≈$240+ per month if left running |
| 2 | Right-size `vm-cost-audit-demo` from B2ls v2 (2 vCPU/4GiB) to a smaller B-series SKU (e.g. B1ls v2/B1s) | Medium | Typically 40–60% VM compute cost reduction at this utilization |
| 3 | Enable an auto-shutdown schedule on the VM for non-business hours | Medium | Cuts billable runtime for a demo/dev workload |
| 4 | Move `storagecostaudit` from Hot to Cool/Archive if data is infrequently accessed | Low–Medium | Cool tier is materially cheaper per GB than Hot |
| 5 | Set Cost Management budget alerts at 50%/80%/100% of the $20/mo budget | Governance | Earlier warning before overspend |
| 6 | Action and close the open Azure Advisor cost recommendation (currently 0% complete) | High | Brings Advisor Cost score up from 37% |

## 6. Before-and-After Comparison

### 6.1 Cost

| Metric | Before (as audited) | After (projected, once recs 1–4 applied) |
|---|---|---|
| Month-to-date spend (5 days) | $22.01 | ≈ $5.63 (removes the $16.38 orphan-disk charge) |
| Largest cost driver | Unattached disk — 74.4% of spend | Right-sized VM/storage — no single unmanaged resource dominates |
| Budget status (day 5) | Over budget by 10% | Well within the $20/month budget |
| Storage cost | $17.35 | ≈ $0.97 (orphan disk removed) |

*The "after" figures reflect removing the orphaned disk (the fully evidence-backed
action) and are directional for VM/storage tiering changes, which depend on actual
future usage. Re-validate in Cost Management after each change.*

### 6.2 Azure Advisor Cost score

| Metric | Before | After (target) |
|---|---|---|
| Advisor Cost score | 37% | Materially higher once the orphaned-disk recommendation is actioned |
| Active cost recommendations | 1 open (0% complete) | 0 open |
| Resource-group Advisor coverage | 1 of 7 (14.3%) | 0 of 7 (0%) |

## 7. Implementation Plan

- **Week 1:** confirm `orphan-disk-demo` isn't needed (check with the team / take a final snapshot if uncertain), then delete it.
- **Week 1:** enable an auto-shutdown schedule on `vm-cost-audit-demo`.
- **Week 2:** right-size the VM SKU based on confirmed workload requirements; monitor CPU/RAM for 7 days post-change.
- **Week 2:** review `storagecostaudit`'s access pattern and move to Cool tier if appropriate.
- **Ongoing:** run `Audit-CloudCosts.ps1` monthly (Task Scheduler / cron+pwsh / Azure Automation runbook) to catch new orphaned disks, idle VMs, and budget drift automatically.
- **Ongoing:** review the Advisor Cost score and Cost Management budget alerts weekly.

## 8. Repository / Deliverables Contents

```
.
├── README.md                                  <- this file
├── Cloud_Cost_Optimization_Audit_Report.docx   <- full formatted audit report (all figures/screenshots)
├── Step_by_Step_Guide.docx                     <- how to reproduce this audit in your own subscription
├── Audit-CloudCosts.ps1                        <- PowerShell automation script (see below)
└── images/                                     <- screenshots referenced by the audit report
```

## 9. Running the PowerShell Automation Script

`Audit-CloudCosts.ps1` reproduces the manual checks in this audit automatically, and can
optionally remediate findings interactively.

### Prerequisites

```powershell
Install-Module Az -Scope CurrentUser
```

Requires the `Az.Accounts`, `Az.Compute`, `Az.CostManagement`, `Az.Advisor`, and
`Az.Monitor` sub-modules (all included in the `Az` module).

### Read-only audit (safe default — no changes are made)

```powershell
./Audit-CloudCosts.ps1 -ResourceGroupName "Cost-Audit"
```

This will:
1. Connect to Azure (prompts for sign-in if not already authenticated).
2. List unattached managed disks in the resource group.
3. List VMs with average CPU below the threshold (default 5%) over the last 7 days.
4. Pull month-to-date cost by resource from Cost Management.
5. Pull open Azure Advisor cost recommendations.
6. Export everything to timestamped CSV files.

### Full audit + interactive remediation

```powershell
./Audit-CloudCosts.ps1 -ResourceGroupName "Cost-Audit" -Remediate -OutputPath ./Reports
```

With `-Remediate`, the script will additionally **ask for confirmation, per resource,
before**:
- Deleting an unattached disk
- Enabling an auto-shutdown schedule on an idle VM

**Nothing is ever deleted or changed without an explicit `y` confirmation at runtime.**

### Useful parameters

| Parameter | Default | Purpose |
|---|---|---|
| `-SubscriptionId` | current context | Target a specific subscription |
| `-ResourceGroupName` | `Cost-Audit` | Scope the audit to one resource group |
| `-CpuThresholdPercent` | `5.0` | CPU % below which a VM is flagged as idle |
| `-LookbackDays` | `7` | Metrics window for CPU averaging |
| `-Remediate` | off | Enables interactive delete/auto-shutdown actions |
| `-OutputPath` | `.` | Folder for exported CSV findings |

### Recommended schedule

Run this monthly — e.g. via Windows Task Scheduler, a cron job calling `pwsh`, or an
Azure Automation runbook — so orphaned disks, idle VMs, and budget overruns are caught
automatically instead of during an annual audit.

## 10. Screenshot Index (see the .docx report for the images themselves)

| # | Source screen |
|---|---|
| 1 | Azure Advisor — Overview |
| 2 | Azure Advisor — Advisor score |
| 3 | Azure Advisor — Cost-Audit recommendations |
| 4 | Cost Management — Cost analysis (Cost-Audit, Aug 2026) |
| 5 | `vm-cost-audit-demo` — Overview / size |
| 6 | `vm-cost-audit-demo` — Metrics (Avg % CPU) |
| 7 | `vm-cost-audit-demo` — Essentials (status) |
| 8 | `storagecostaudit` — Overview / essentials |
| 9 | `storagecostaudit` — Blob service & security settings |
| 10 | `orphan-disk-demo` — Overview / essentials |
| 11 | `orphan-disk-demo` — Size, performance, encryption |

---

*Prepared as part of a capstone project addressing the problem context: "Startups
overspend on cloud services." All figures above are taken directly from the audited
Azure environment (screenshots in the accompanying `.docx` report).*
