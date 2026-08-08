# Nigeria Cloud Cost Optimization Audit — Step-by-Step Guide

---

## . Step-by-Step Guide (Azure Portal / GUI)

This section walks through the audit exactly as performed for this submission, using the Azure Portal graphical interface (Option A: manual GUI creation) against the resource group Cost-Audit in South Africa North.

### Step 1 — Create a Resource Group
1. Signed in to portal.azure.com.
2. Searched for "Resource groups" and selected it.
3. Clicked + Create, named it **Cost-Audit**, and chose the **South Africa North** region (closest full-service Azure region to Nigeria).
4. Clicked Review + create, then Create.

### Step 2 — Deploy the Baseline ("Before") Environment
Deployed manually via the GUI (Option A):
- Created a Virtual Machine: `vm-cost-audit-demo`, Ubuntu 22.04 LTS, size Standard B2ls v2 (2 vCPU / 4 GiB), Trusted launch security (Secure boot + vTPM enabled).
- Created a Managed Disk, `orphan-disk-demo` (1024 GiB, Premium SSD v2, LRS), and deliberately left it unattached to simulate a leftover test resource.
- Created a Storage Account, `storagecostaudit` (StorageV2, Standard performance, LRS, Hot default tier) to hold logs/backups, as the reference architecture calls for.

**Figure 1 — VM Essentials: resource group Cost-Audit, size, region, status**
![VM Essentials](../images/Resource_Group_screen_short.png)

**Figure 2 — Orphaned disk Essentials: 1024 GiB, Premium SSD v2, Unattached**
![Orphaned disk Essentials](../images/Ophan_disk_demo.png)

**Figure 3 — Storage account Essentials: storagecostaudit, StorageV2, LRS, southafricanorth**
![Storage account Essentials](../images/Storage_cost_audit.png)

*The environment was left running for the audit window (Aug 1–8, 2026) so Azure Monitor and Advisor could collect enough telemetry for meaningful recommendations.*

### Step 3 — Review Usage with Azure Monitor
5. Opened the `vm-cost-audit-demo` VM resource, then Monitoring > Metrics.
6. Added metric Percentage CPU, time range Last 7 days, aggregation Average.
7. Observed average CPU of **0.1719%** — far under the 10–20% threshold that would justify the current VM size.
8. Captured the chart below as evidence for the audit report.

**Figure 4 — Avg Percentage CPU for vm-cost-audit-demo: 0.1719% average over 7 days**
![Azure Monitor CPU usage](../images/Review_Usage_with_Azure_Monitor.png)

### Step 4 — Pull Recommendations from Azure Advisor
9. Searched "Advisor" in the Portal and opened it.
10. Reviewed the Cost tab: **Cost score 37%**, versus 89–100% for every other category.
11. Found one active Medium-impact recommendation: "Review disks that are not attached to a VM and evaluate if you still need the disks", affecting 1 of 7 resources (14.3%).
12. Captured the Advisor overview, score detail, and recommendation list below.

**Figure 5 — Advisor Overview: Cost score 37%, Security fully compliant, Reliability 89%, Operational excellence 100%**
![Advisor Overview](../images/Pull_Recommendations_from_Azure_Advisor.png)

**Figure 6 — Advisor score detail: 81% overall, per-category breakdown**
![Advisor score detail](../images/Advisor_score.png)

**Figure 7 — Advisor: active cost recommendation flagging the unattached disk**
![Advisor recommendation](../images/Advisor_recommendation.png)

### Step 5 — Review Cost Analysis
13. Searched "Cost Management" and opened Cost Management + Billing.
14. Opened Cost analysis, scoped to the Cost-Audit resource group.
15. Recorded month-to-date actual cost of **$22.01** against the configured **$20/mo** budget — already 10% over budget by day 5 of the month.
16. Grouped by Service name and by Resource: Storage $17.35 (78.8%), Virtual Machines $3.53 (16.0%), Virtual Network $1.12 (5.1%); by resource, the orphaned disk alone was **$16.38 (74% of total spend)**.

**Figure 8 — Cost analysis: $22.01 accumulated cost vs. $20/mo budget, by service/location/resource**
![Cost analysis](../images/Review_Cost_Analysis.png)

### Step 6 — Apply Rightsizing Recommendations
Based on the findings above, the following actions are recommended for this environment:
- Delete the unattached `orphan-disk-demo` (1024 GiB Premium SSD v2) once confirmed unneeded, or reattach it if still required — this alone removes 74% of current spend.
- Enable VM auto-shutdown on `vm-cost-audit-demo` (currently Not enabled) for off-hours, given the observed 0.17% CPU utilization; or downsize from B2ls v2 to a smaller burstable SKU.
- Restrict `storagecostaudit`'s public network access (currently "Enabled from all networks") to only what's required, as a hardening follow-up alongside the cost cleanup.

*Note: for this submission the VM was stopped (deallocated) rather than resized, and the orphaned disk was retained un-deleted specifically so its cost impact could be measured and documented in this report.*

### Step 7 — Re-measure and Compare
17. Estimated the optimized run-rate by removing the orphaned disk's cost in full and applying a conservative 50% reduction to VM compute from scheduling/rightsizing.
18. Built the before/after comparison table (Section 3.2 / Section 6.4).
19. Captured the cost analysis screenshot above as the "before" baseline for the next audit cycle's comparison.

### Step 8 — Write and Export the Audit Report
20. Filled in the Audit Report Template (Section 6) with the actual findings, screenshots, and numbers captured above.
21. Exported/finalized as the Word document and this accompanying README.md.

---

---

For full context (problem statement, architecture note, completed audit report, and recommendations), see the [main README](../README.md) or [Cloud-Cost-Optimization-Audit-FINAL.docx](./Cloud-Cost-Optimization-Audit-FINAL.docx) in this repo.

