# Cloud Cost Optimization Audit (MVP)

**Problem:** Startups (including many in Nigeria) routinely overspend on cloud infrastructure because nobody has time to regularly audit usage vs. billed cost. Orphaned resources and oversized VMs quietly burn budget every month.

**What this project does:** Audits a sample Azure environment using only native Azure tooling and produces a structured report with cost-saving recommendations and a before/after savings estimate.

## MVP Features delivered

| Feature | How it was implemented |
|---|---|
| Usage review | Azure Monitor metrics (avg CPU %) pulled for the audited VM over a 7-day window |
| Cost-saving recommendations | Azure Cost Management (Cost Analysis) + Azure Advisor cost recommendations, cross-checked against each other |
| Before-and-after comparison | Section 5 of the audit report: current spend vs. projected spend after applying recommendations |
| Audit report | [`Cloud_Cost_Optimization_Audit_Report.docx`](./Cloud_Cost_Optimization_Audit_Report.docx) — full write-up with embedded screenshots, tables, and numbers |

## Environment audited

- **Provider:** Microsoft Azure
- **Subscription:** Azure subscription 1
- **Resource group:** `Cost-Audit` (South Africa North region)
- **Resources:** 1 Linux VM (`vm-cost-audit-demo`, Standard B2ls v2), 1 unattached managed disk, 1 virtual network, 1 public IP
- **Audit window:** Cost data Aug 1–5, 2026 (month-to-date); usage data trailing 7 days as of Aug 5, 2026

## Headline finding

**74% of monthly spend ($16.38 of $22.01) was going to a disk that was not attached to any VM.** The VM itself was running at an average of **0.17% CPU utilization** over 7 days on a burstable 2-vCPU size, with no auto-shutdown schedule configured. Azure Advisor's Cost score for the subscription was 37% — the clear outlier against Security, Reliability (89%), Operational Excellence (100%), and Performance (100%).

## Before / After

| | Before | After (est.) |
|---|---|---|
| Monthly spend | $22.01 | ~$5.63 |
| vs. $20/mo budget | 10% over | ~72% under |
| Primary driver | Orphaned disk ($16.38) + underused VM | Disk removed, VM rightsized/scheduled |

**Estimated savings: ~$16.38/month (74%)** — see Section 5 of the full report for the calculation basis and a conservative-to-optimistic range.

## Recommendations (priority order)

1. **Delete or reassess the orphaned disk** — confirm it's not needed, then delete (or snapshot first if unsure). ~$16.38/mo saving.
2. **Rightsize or schedule the VM** — enable auto-shutdown for off-hours, or downsize the SKU given ~0.17% observed CPU use. ~$0.88–$2.47/mo saving, growing with scale.
3. **Institutionalize the review** — budget alerts at 80% threshold, Advisor recommendation digests, and resource tagging so this audit becomes a repeatable monthly habit instead of a one-off exercise.

Full detail, methodology, and every supporting screenshot are in the audit report.

## Methodology (4-step MVP workflow)

1. **Usage review** — Azure Monitor → VM metrics → Avg Percentage CPU
2. **Cost review** — Azure Cost Management → Cost analysis, grouped by service / location / resource
3. **Recommendation pull** — Azure Advisor → Cost recommendations + Advisor score
4. **Before/after comparison** — consolidate findings into a savings estimate and prioritized action list

This workflow uses only tools already available in the Azure Portal (no third-party cost platform), so it can be repeated by any small team with no dedicated FinOps headcount.

## Files in this repo

- `Cloud_Cost_Optimization_Audit_Report.docx` — the full audit report (7 sections + appendix, with all source screenshots embedded)
- `README.md` — this summary

## Report sections

1. Executive Summary
2. Scope & Methodology
3. Environment Overview
4. Findings (Cost Analysis, Advisor Recommendations, Advisor Score, Usage Review)
5. Before / After Comparison
6. Recommendations
7. Conclusion
Appendix A — Source Screenshots
