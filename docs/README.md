# Cloud Cost Optimization Audit

**Rightsizing Recommendations for a Sample Azure Environment**

| | |
|---|---|
| **Prepared for** | Startup Cloud Cost Optimization Initiative |
| **Environment audited** | Azure Resource Group "Cost-Audit" (Azure subscription 1) |
| **Audit period** | August 1 – 5, 2026 |
| **Report date** | August 8, 2026 |

> **Problem context:** Startups in Nigeria (and similar emerging markets) frequently overspend on cloud infrastructure due to orphaned resources, oversized compute, and a lack of routine cost review. This audit demonstrates an MVP workflow — usage review, cost-saving recommendations, before/after comparison, and a structured audit report — that any small team can repeat monthly.

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Scope & Methodology](#2-scope--methodology)
3. [Environment Overview](#3-environment-overview)
4. [Findings](#4-findings)
5. [Before / After Comparison](#5-before--after-comparison)
6. [Recommendations](#6-recommendations)
7. [Conclusion](#7-conclusion)
   - [Appendix A — Source Screenshots](#appendix-a--source-screenshots)

---

## 1. Executive Summary

This audit reviewed a sample Azure environment (resource group "Cost-Audit") representing a typical early-stage startup workload: one Linux virtual machine, its networking stack, and associated storage. The objective was to identify unnecessary spend and produce concrete, low-risk rightsizing recommendations.

**Key finding:** the environment is spending 74% of its monthly cloud bill on a storage disk that is not attached to any virtual machine. Combined with a virtual machine that is provisioned far beyond what its actual CPU usage requires, the audited environment is on track to exceed its own monthly budget while the compute it is paying for sits almost completely idle.

**Table 1 — Before/after summary** (see Section 5 for calculation basis)

| Metric | Current (Before) | Optimized (After) |
|---|---|---|
| Monthly spend (MTD, Aug 2026) | $22.01 | ~$5.63 (est.) |
| Monthly budget | $20.00 | $20.00 |
| Budget status | 10% over budget 🔴 | ~72% under budget 🟢 |
| Advisor Cost score | 37% | Expected to rise once actioned |
| Average VM CPU utilization (7 days) | 0.17% | N/A — VM stopped/rightsized |
| Estimated monthly savings | — | **~$16.38 (74%)** |

Full findings, screenshots, and the calculation basis for these figures are provided in Sections 3–6.

---

## 2. Scope & Methodology

### 2.1 Scope

- **Cloud provider:** Microsoft Azure
- **Subscription:** Azure subscription 1
- **Resource group audited:** Cost-Audit (South Africa North region)
- **Resources in scope:** 1 virtual machine (`vm-cost-audit-demo`), 1 unattached managed disk, 1 virtual network, 1 public IP
- **Audit window:** cost data for August 1–5, 2026 (month-to-date); usage data for the trailing 7 days as of August 5, 2026

### 2.2 Methodology

The audit followed a four-step MVP workflow, using native Azure tooling only (no third-party cost tools), to keep the process reproducible by a small team with no dedicated FinOps staff:

1. **Usage review** — Azure Monitor metrics were pulled for the virtual machine to establish actual resource consumption (CPU) against the size that is being paid for.
2. **Cost review** — Azure Cost Management › Cost analysis was used to break month-to-date spend down by service, location, and individual resource.
3. **Recommendation pull** — Azure Advisor's Cost recommendations and Advisor score were pulled for the same scope to cross-check the manual findings against Microsoft's own optimization engine.
4. **Before/after comparison** — Findings were consolidated into a single savings estimate and a set of prioritized, actionable recommendations (Sections 5–6).

---

## 3. Environment Overview

The audited environment consists of a single-VM baseline deployment, described below as captured directly from the Azure Portal.

| Property | Value |
|---|---|
| Resource group | Cost-Audit |
| VM name | vm-cost-audit-demo |
| Operating system | Linux – Ubuntu 22.04 LTS (Ubuntu Pro image) |
| VM size | Standard B2ls v2 (burstable, 2 vCPU) |
| Region / Zone | South Africa North, Availability zone 1 |
| Status at time of audit | Stopped (deallocated) |
| Public IP | 4.222.218.107 |
| Private IP | 10.0.0.4 |
| Virtual network | vm-cost-audit-demo-vnet / default subnet |
| OS disk | vm-cost-audit-demo_OsDisk_1 (no data disks attached) |
| Security | Trusted launch, Secure boot enabled, vTPM enabled |
| Auto-shutdown | Not enabled |
| Time created | 8/3/2026, 12:39 PM UTC |

**Figure 1 — VM Essentials: resource group, size, region, and status**

![VM Essentials](images/Resource_Group_screen_short.png)

**Figure 2 — VM hardware, networking, and image configuration**

![VM hardware and networking](images/Deploy_the_Baseline_Before_Environment.png)

**Figure 3 — Availability, security, and disk configuration (no data disks, auto-shutdown disabled)**

![Availability, security, and disk configuration](images/Deploy_the_Baseline_Before_Environment_2.png)

---

## 4. Findings

### 4.1 Cost Analysis

Month-to-date (Aug 1–31, 2026) accumulated cost for the Cost-Audit resource group was **$22.01** against a configured monthly budget of **$20** — already 10% over budget just 5 days into the month, with the forecast line crossing the budget threshold around August 7.

**Figure 4 — Cost analysis: accumulated cost vs. $20/mo budget, broken down by service, location, and resource**

![Cost analysis](images/Review_Cost_Analysis.png)

**Breakdown by service name:**

| Service | Cost (USD) | % of total |
|---|---|---|
| Storage | $17.35 | 78.8% |
| Virtual Machines | $3.53 | 16.0% |
| Virtual Network | $1.12 | 5.1% |
| Bandwidth | < $0.01 | ~0% |

Breakdown by individual resource is the most revealing view: a single disk, `orphan-disk-de…`, not attached to any running VM, accounts for **$16.38 — 74% of total spend** — versus $3.53 for the actual running VM (`vm-cost-audit-d…`) and $0.97 for its OS disk. All spend is concentrated in the **za north** (South Africa North) region.

**Interpretation**

- The single largest cost driver in this environment is not compute at all — it is an orphaned disk that is no longer attached to any virtual machine but continues to be billed for its provisioned capacity.
- This is a common and easily-missed cost leak: a disk survives after its VM is resized, rebuilt, or deleted, and nobody notices because it never appears in compute cost views.
- Storage costs alone ($17.35) already exceed the entire monthly budget ($20 threshold almost reached by storage costs alone), meaning even a well-utilized VM would not bring this environment back under budget without addressing the orphaned disk.

### 4.2 Azure Advisor Recommendations

Azure Advisor was queried for active recommendations across the Cost-Audit resource group, filtered to a 3-year/30-day reserved-instance commitment horizon.

**Figure 5 — Advisor: 1 active cost recommendation affecting 1 of 7 resources (14.3%)**

![Advisor recommendations](images/Advisor_recommendation.png)

| Recommendation | Impact | Affected resources | Completion | Potential savings |
|---|---|---|---|---|
| Review disks that are not attached to a VM and evaluate if you still need the disks | Medium | 1 of 1 disks | 0% | No data (Advisor) |

This Advisor recommendation independently confirms the manual cost-analysis finding in Section 4.1: the orphaned disk is the single actionable cost item in the environment. Advisor reports "no data" for potential savings because disk retail pricing isn't attributed automatically — Section 5 of this report derives that figure directly from the Cost Analysis breakdown ($16.38/month, i.e., the disk's full billed cost, since it delivers zero value while unattached).

### 4.3 Advisor Score

Azure Advisor's composite score for this subscription was **81% overall**, driven down almost entirely by a weak Cost score.

**Figure 6 — Advisor score overview: Cost 37%, Reliability 89%, Operational excellence 100%, security fully compliant**

![Advisor score overview](images/Pull_Recommendations_from_Azure_Advisor.png)

**Figure 7 — Advisor score detail: 81% overall, with per-category breakdown and refresh timestamps**

![Advisor score detail](images/Advisor_score.png)

| Category | Score |
|---|---|
| Overall Advisor score | 81% |
| Cost score | 37% |
| Security score | Not available (following all recommendations) |
| Reliability score | 89% |
| Operational excellence score | 100% |
| Performance score | 100% |

The Cost score of 37% is a clear outlier against every other category and is the category this audit directly targets. Security, reliability, operational excellence, and performance are already in good standing — the environment's problem is specifically wasted spend, not architecture or safety.

### 4.4 Usage Review (Azure Monitor)

Average CPU utilization for `vm-cost-audit-demo` was pulled from Azure Monitor for the trailing 7 days.

**Figure 8 — Avg Percentage CPU for vm-cost-audit-demo: 0.1719% average over 7 days**

![Azure Monitor CPU usage](images/Review_Usage_with_Azure_Monitor.png)

- 7-day average CPU utilization: **0.1719%** (effectively idle)
- The VM is a Standard B2ls v2 (2 vCPU, burstable) — provisioned for bursts of activity that this workload never exercises
- The VM was subsequently stopped/deallocated by August 3, consistent with a demo/dev workload that does not need to run continuously

**Interpretation**

- A workload running at ~0.17% CPU for a full week does not need a dedicated burstable VM running continuously — it is a strong candidate for either a smaller size, a scheduled auto-shutdown, or an on-demand/serverless pattern.
- No auto-shutdown schedule is configured (Section 3), so absent manual intervention, this VM would otherwise continue billing 24/7 for single-digit-percent utilization.

---

## 5. Before / After Comparison

The table below converts the findings in Section 4 into a concrete monthly savings estimate. "Before" figures come directly from the Cost Analysis resource-level breakdown (Figure 4); "After" figures assume the two recommended actions in Section 6 are applied and no new spend is added.

| Cost item | Before (current) | Action | After (optimized) |
|---|---|---|---|
| Orphaned disk (orphan-disk-de…) | $16.38 / mo | Delete (confirmed unneeded) or reattach if still required | $0.00 / mo |
| VM OS disk | $0.97 / mo | Keep — required for the VM to run | $0.97 / mo |
| Virtual Machine compute (vm-cost-audit-d…) | $3.53 / mo | Rightsize / enable auto-shutdown outside working hours (~0.17% CPU observed) | ~$1.06–$2.65 / mo (est. 25–70% reduction) |
| Virtual Network | $1.12 / mo | No change — required networking cost | $1.12 / mo |
| Bandwidth | < $0.01 / mo | No change | < $0.01 / mo |
| **Total** | **$22.01 / mo** | — | **~$3.15–$4.74 / mo (compute) + fixed = ~$5.24–$6.83 / mo** |

Using a conservative midpoint (50% reduction on VM compute from rightsizing/scheduling, full removal of the orphaned disk), estimated new monthly spend is approximately **$5.63**, a reduction of about **$16.38 (74%)** from the current $22.01/month run rate. Even the most conservative scenario in the range above keeps the environment comfortably under the $20/month budget, versus being 10% over budget today.

> **Bottom line:** roughly three-quarters of this environment's monthly Azure bill is currently being spent on a disk that is doing no useful work. Removing it alone resolves the budget overage; rightsizing the VM compounds the saving further.

---

## 6. Recommendations

Recommendations are ordered by impact and ease of implementation. All are low-risk and reversible except disk deletion, which is flagged accordingly.

### 6.1 Priority 1 — Remove the orphaned disk

**Impact:** ~$16.38/month (74% of current spend). **Effort:** Low. **Risk:** Confirm no data is needed before deleting.

- Open Azure Advisor › Cost recommendations → "Review disks that are not attached to a VM and evaluate if you still need the disks."
- Verify the disk's content is not needed (check disk name/tags, creation date, and whether it corresponds to a deleted or resized VM).
- If not needed: delete the disk directly from the Cost-Audit resource group.
- If a snapshot might be needed later, take a low-cost snapshot before deleting the full disk — snapshots are billed at a fraction of the full managed-disk rate.

### 6.2 Priority 2 — Rightsize or schedule the virtual machine

**Impact:** ~$0.88–$2.47/month, growing over time as the environment scales. **Effort:** Low–Medium. **Risk:** Low (reversible).

- Observed 7-day average CPU utilization is 0.17% on a Standard B2ls v2 — far below the burst threshold this size is built for.
- Enable Auto-shutdown (currently "Not enabled") for a fixed schedule (e.g., shut down outside working hours) if this is a dev/test workload.
- If the workload is truly always-idle, evaluate downsizing to a smaller burstable SKU (e.g., B1ls) or consolidating onto a shared dev VM.
- Re-check Azure Monitor CPU/memory metrics after 1–2 weeks of normal use before committing to a permanent size change.

### 6.3 Priority 3 — Institutionalize the review (make this repeatable)

**Impact:** Prevents future orphaned-resource and over-provisioning costs from recurring. **Effort:** Low (one-time setup).

- Create a Cost Management budget alert (in addition to the existing $20/mo budget) that notifies the team by email when actual or forecasted cost crosses 80% of budget — this audit's overage was visible in Cost Analysis but no alert had fired.
- Schedule a recurring Advisor "recommendation digest" (available directly from the Advisor recommendations screen) so cost recommendations land in someone's inbox automatically instead of requiring a manual portal visit.
- Tag all resources with an owner and environment (dev/test/prod) so orphaned resources are traceable back to a person or project when Advisor flags them.
- Repeat this 4-step audit (usage review → cost analysis → Advisor pull → before/after comparison) monthly, or automate it as the audited MVP is extended.

### 6.4 Summary of recommended actions

| # | Recommendation | Est. monthly saving | Effort | Risk |
|---|---|---|---|---|
| 1 | Delete/reassess orphaned disk | $16.38 | Low | Low (verify first) |
| 2 | Auto-shutdown / rightsize VM | $0.88–$2.47 | Low–Medium | Low |
| 3 | Budget alerts + recommendation digest + tagging | Preventive (not one-off) | Low | None |

---

## 7. Conclusion

This audit set out to demonstrate a lightweight, repeatable cloud cost optimization workflow suited to early-stage startups that lack dedicated FinOps resources. Using only native Azure tooling — Cost Management, Azure Advisor, and Azure Monitor — a single unattached disk was identified as responsible for nearly three-quarters of the audited environment's monthly spend, alongside a virtual machine running at under 1% of its provisioned CPU capacity.

Acting on the two priority recommendations in Section 6 is projected to reduce monthly spend from $22.01 to roughly $5.24–$6.83 — bringing a currently over-budget environment to well under 35% of its $20/month budget — with no loss of functionality and minimal engineering effort. The third recommendation (alerts, digests, tagging) is what turns this from a one-time saving into a durable, repeatable practice, which is the outcome startups actually need to stop overspending on cloud services on an ongoing basis.

---

## Appendix A — Source Screenshots

All figures referenced in this report were captured directly from the Azure Portal for the Cost-Audit resource group / Azure subscription 1 between August 4–5, 2026, and are reproduced in full in Sections 3–4 above. No data has been altered; dollar figures and percentages are transcribed as-shown.

| Figure | File | Description |
|---|---|---|
| 1 | `images/Resource_Group_screen_short.png` | VM Essentials: resource group, size, region, status |
| 2 | `images/Deploy_the_Baseline_Before_Environment.png` | VM hardware, networking, image configuration |
| 3 | `images/Deploy_the_Baseline_Before_Environment_2.png` | Availability, security, disk configuration |
| 4 | `images/Review_Cost_Analysis.png` | Cost analysis: accumulated cost vs. budget |
| 5 | `images/Advisor_recommendation.png` | Advisor active cost recommendation (orphaned disk) |
| 6 | `images/Pull_Recommendations_from_Azure_Advisor.png` | Advisor score overview (Cost, Security, Reliability, Operational excellence) |
| 7 | `images/Advisor_score.png` | Advisor score detail (81% overall, per-category breakdown) |
| 8 | `images/Review_Usage_with_Azure_Monitor.png` | Azure Monitor: Avg Percentage CPU (7-day) |
