#Requires -Modules Az.Accounts, Az.Compute, Az.CostManagement, Az.Advisor
<#
.SYNOPSIS
    Cloud Cost Optimization Audit - PowerShell automation script.

.DESCRIPTION
    Companion script to the "Cloud Cost Optimization Audit Report" capstone project.
    Automates the checks that were performed manually against the Cost-Audit resource
    group in this audit:
      1. Finds unattached (orphaned) managed disks and reports their size/cost impact.
      2. Finds VMs with low average CPU utilization over a trailing window (idle/oversized).
      3. Pulls current month-to-date cost by resource from Azure Cost Management.
      4. Pulls open Azure Advisor cost recommendations.
      5. (Optional, -Remediate) Enables VM auto-shutdown and/or deletes confirmed
         orphaned disks, with a mandatory interactive confirmation per resource.

    Designed to be run on a schedule (Task Scheduler, cron via pwsh, or an Azure
    Automation runbook) so this review does not depend on a person remembering to
    do it manually every month.

.PARAMETER SubscriptionId
    The Azure subscription to audit. Defaults to the current context if omitted.

.PARAMETER ResourceGroupName
    Restrict the audit to a single resource group (recommended). Example: "Cost-Audit".

.PARAMETER CpuThresholdPercent
    VMs whose average CPU over -LookbackDays is below this value are flagged as
    idle / candidates for rightsizing. Default: 5.

.PARAMETER LookbackDays
    Number of days of Azure Monitor metrics to average. Default: 7.

.PARAMETER Remediate
    Switch. When present, the script will interactively offer to:
      - Enable an auto-shutdown schedule on flagged idle VMs
      - Delete confirmed orphaned (unattached) disks
    Without this switch the script only reports findings (safe / read-only mode).

.PARAMETER OutputPath
    Folder to write the CSV/JSON findings to. Default: current directory.

.EXAMPLE
    # Read-only audit of the Cost-Audit resource group (safe default)
    ./Audit-CloudCosts.ps1 -ResourceGroupName "Cost-Audit"

.EXAMPLE
    # Full audit + interactive remediation, output saved to a Reports folder
    ./Audit-CloudCosts.ps1 -ResourceGroupName "Cost-Audit" -Remediate -OutputPath ./Reports

.NOTES
    Author   : Capstone Project - Cloud Cost Optimization Audit for Nigerian Startups
    Requires : Az.Accounts, Az.Compute, Az.CostManagement, Az.Advisor, Az.Monitor
               Install with: Install-Module Az -Scope CurrentUser
    Safety   : Read-only by default. All delete/change actions require -Remediate
               AND an explicit per-resource "y" confirmation at runtime. Nothing is
               deleted silently.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $false)]
    [string]$ResourceGroupName = "Cost-Audit",

    [Parameter(Mandatory = $false)]
    [double]$CpuThresholdPercent = 5.0,

    [Parameter(Mandatory = $false)]
    [int]$LookbackDays = 7,

    [Parameter(Mandatory = $false)]
    [switch]$Remediate,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "."
)

# ---------------------------------------------------------------------------
# 0. Setup
# ---------------------------------------------------------------------------
$ErrorActionPreference = "Stop"
$timestamp   = Get-Date -Format "yyyyMMdd-HHmmss"
$reportStamp = Get-Date -Format "yyyy-MM-dd HH:mm"

if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host ("=" * 70) -ForegroundColor Cyan
    Write-Host " $Title" -ForegroundColor Cyan
    Write-Host ("=" * 70) -ForegroundColor Cyan
}

function Confirm-Action {
    param([string]$Message)
    $resp = Read-Host "$Message [y/N]"
    return ($resp -match '^(y|yes)$')
}

# ---------------------------------------------------------------------------
# 1. Connect
# ---------------------------------------------------------------------------
Write-Section "Connecting to Azure"

$context = Get-AzContext
if (-not $context) {
    Connect-AzAccount | Out-Null
    $context = Get-AzContext
}

if ($SubscriptionId) {
    Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
    $context = Get-AzContext
}

Write-Host "Connected as: $($context.Account.Id)"
Write-Host "Subscription: $($context.Subscription.Name)  ($($context.Subscription.Id))"
Write-Host "Scope       : Resource group '$ResourceGroupName'"
Write-Host "Mode        : $(if ($Remediate) { 'REMEDIATE (interactive confirmation required per action)' } else { 'READ-ONLY (report only)' })"

$subId = $context.Subscription.Id

# ---------------------------------------------------------------------------
# 2. Finding 1 — Orphaned / unattached managed disks
# ---------------------------------------------------------------------------
Write-Section "Finding 1: Unattached managed disks"

$disks = Get-AzDisk -ResourceGroupName $ResourceGroupName |
    Where-Object { $_.DiskState -eq "Unattached" }

$diskFindings = foreach ($d in $disks) {
    [PSCustomObject]@{
        DiskName       = $d.Name
        ResourceGroup  = $ResourceGroupName
        SizeGiB        = $d.DiskSizeGB
        Sku            = $d.Sku.Name
        Region         = $d.Location
        DiskState      = $d.DiskState
        TimeCreated    = $d.TimeCreated
        Recommendation = "Unattached and not in use — confirm with team, snapshot if data must be retained, then delete."
    }
}

if ($diskFindings) {
    $diskFindings | Format-Table -AutoSize
    $diskFindings | Export-Csv -Path (Join-Path $OutputPath "orphaned-disks-$timestamp.csv") -NoTypeInformation
    Write-Host "-> $($diskFindings.Count) unattached disk(s) found. Largest waste driver in most audits." -ForegroundColor Yellow
} else {
    Write-Host "No unattached disks found in '$ResourceGroupName'." -ForegroundColor Green
}

# ---------------------------------------------------------------------------
# 3. Finding 2 — Idle / low-utilization VMs
# ---------------------------------------------------------------------------
Write-Section "Finding 2: Low-CPU-utilization virtual machines (last $LookbackDays days)"

$vms = Get-AzVM -ResourceGroupName $ResourceGroupName -Status

$vmFindings = foreach ($vm in $vms) {
    $endTime   = Get-Date
    $startTime = $endTime.AddDays(-$LookbackDays)

    try {
        $metric = Get-AzMetric -ResourceId $vm.Id `
            -MetricName "Percentage CPU" `
            -TimeGrain 01:00:00 `
            -StartTime $startTime -EndTime $endTime `
            -AggregationType Average -WarningAction SilentlyContinue

        $avgCpu = ($metric.Data | Where-Object { $_.Average -ne $null } |
            Measure-Object -Property Average -Average).Average
    } catch {
        $avgCpu = $null
    }

    $powerState = ($vm.Statuses | Where-Object { $_.Code -like "PowerState/*" }).DisplayStatus

    [PSCustomObject]@{
        VMName            = $vm.Name
        ResourceGroup     = $ResourceGroupName
        Size              = $vm.HardwareProfile.VmSize
        PowerState        = $powerState
        AvgCpuPercent     = if ($avgCpu) { [math]::Round($avgCpu, 2) } else { "n/a" }
        FlaggedIdle       = ($avgCpu -ne $null -and $avgCpu -lt $CpuThresholdPercent)
        AutoShutdownFound = $false   # set below
    }
}

foreach ($f in $vmFindings) {
    $schedule = Get-AzResource -ResourceGroupName $ResourceGroupName `
        -ResourceType "Microsoft.DevTestLab/schedules" `
        -Name "shutdown-computevm-$($f.VMName)" -ErrorAction SilentlyContinue
    $f.AutoShutdownFound = [bool]$schedule
}

$vmFindings | Format-Table -AutoSize
$vmFindings | Export-Csv -Path (Join-Path $OutputPath "vm-utilization-$timestamp.csv") -NoTypeInformation

$idleVms = $vmFindings | Where-Object { $_.FlaggedIdle }
if ($idleVms) {
    Write-Host "-> $($idleVms.Count) VM(s) below $CpuThresholdPercent% avg CPU — candidates for rightsizing / auto-shutdown." -ForegroundColor Yellow
}

# ---------------------------------------------------------------------------
# 4. Finding 3 — Month-to-date cost by resource
# ---------------------------------------------------------------------------
Write-Section "Finding 3: Month-to-date cost by resource"

$scope = "/subscriptions/$subId/resourceGroups/$ResourceGroupName"
$today = Get-Date
$monthStart = Get-Date -Year $today.Year -Month $today.Month -Day 1

try {
    $usage = Invoke-AzCostManagementQuery -Scope $scope `
        -Timeframe Custom `
        -TimePeriodFrom $monthStart -TimePeriodTo $today `
        -Type ActualCost `
        -DatasetGranularity None `
        -DatasetAggregation @{ totalCost = @{ name = "Cost"; function = "Sum" } } `
        -DatasetGrouping @(@{ type = "Dimension"; name = "ResourceId" })

    $costFindings = $usage.Row | ForEach-Object {
        [PSCustomObject]@{
            ResourceId = $_[1]
            CostUSD    = [math]::Round([double]$_[0], 2)
        }
    } | Sort-Object CostUSD -Descending

    $costFindings | Format-Table -AutoSize
    $costFindings | Export-Csv -Path (Join-Path $OutputPath "cost-by-resource-$timestamp.csv") -NoTypeInformation

    $totalCost = ($costFindings | Measure-Object -Property CostUSD -Sum).Sum
    Write-Host "-> Month-to-date total: `$$totalCost" -ForegroundColor Yellow
} catch {
    Write-Host "Could not query Cost Management (check Az.CostManagement module / permissions): $($_.Exception.Message)" -ForegroundColor Red
}

# ---------------------------------------------------------------------------
# 5. Finding 4 — Open Azure Advisor cost recommendations
# ---------------------------------------------------------------------------
Write-Section "Finding 4: Open Azure Advisor cost recommendations"

try {
    $advisorFindings = Get-AzAdvisorRecommendation |
        Where-Object { $_.Category -eq "Cost" -and $_.ResourceGroup -eq $ResourceGroupName } |
        Select-Object @{N = "Recommendation"; E = { $_.ShortDescriptionSolution } },
                      Impact,
                      @{N = "ResourceName"; E = { $_.ImpactedValue } }

    if ($advisorFindings) {
        $advisorFindings | Format-Table -AutoSize
        $advisorFindings | Export-Csv -Path (Join-Path $OutputPath "advisor-cost-recommendations-$timestamp.csv") -NoTypeInformation
    } else {
        Write-Host "No open Advisor cost recommendations for '$ResourceGroupName'." -ForegroundColor Green
    }
} catch {
    Write-Host "Could not query Azure Advisor (check Az.Advisor module / permissions): $($_.Exception.Message)" -ForegroundColor Red
}

# ---------------------------------------------------------------------------
# 6. Optional remediation (interactive, opt-in only)
# ---------------------------------------------------------------------------
if ($Remediate) {
    Write-Section "Remediation (interactive — nothing changes without your confirmation)"

    # 6a. Orphaned disks -> offer to delete
    foreach ($d in $diskFindings) {
        Write-Host ""
        Write-Host "Disk '$($d.DiskName)' — $($d.SizeGiB) GiB, $($d.Sku), unattached since it was created ($($d.TimeCreated))."
        if (Confirm-Action "Delete this disk permanently?") {
            if ($PSCmdlet.ShouldProcess($d.DiskName, "Remove-AzDisk")) {
                Remove-AzDisk -ResourceGroupName $ResourceGroupName -DiskName $d.DiskName -Force
                Write-Host "Deleted '$($d.DiskName)'." -ForegroundColor Green
            }
        } else {
            Write-Host "Skipped '$($d.DiskName)'."
        }
    }

    # 6b. Idle VMs without auto-shutdown -> offer to enable a schedule
    foreach ($f in ($vmFindings | Where-Object { $_.FlaggedIdle -and -not $_.AutoShutdownFound })) {
        Write-Host ""
        Write-Host "VM '$($f.VMName)' is idle (avg CPU $($f.AvgCpuPercent)%) and has no auto-shutdown schedule."
        if (Confirm-Action "Enable a 7:00 PM daily auto-shutdown for this VM?") {
            $vmResource = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $f.VMName
            $properties = @{
                status     = "Enabled"
                taskType   = "ComputeVmShutdownTask"
                dailyRecurrence = @{ time = "1900" }
                timeZoneId = "UTC"
                targetResourceId = $vmResource.Id
                notificationSettings = @{ status = "Disabled" }
            }
            if ($PSCmdlet.ShouldProcess($f.VMName, "New-AzResource (auto-shutdown schedule)")) {
                New-AzResource -ResourceId "$($vmResource.Id -replace $vmResource.Name, '')/providers/Microsoft.DevTestLab/schedules/shutdown-computevm-$($f.VMName)" `
                    -Location $vmResource.Location -Properties $properties -Force | Out-Null
                Write-Host "Auto-shutdown enabled for '$($f.VMName)'." -ForegroundColor Green
            }
        } else {
            Write-Host "Skipped '$($f.VMName)'."
        }
    }
}

# ---------------------------------------------------------------------------
# 7. Summary
# ---------------------------------------------------------------------------
Write-Section "Summary"
Write-Host "Run completed: $reportStamp"
Write-Host "Unattached disks found : $($diskFindings.Count)"
Write-Host "Idle VMs found         : $($idleVms.Count)"
Write-Host "Findings exported to   : $(Resolve-Path $OutputPath)"
Write-Host ""
Write-Host "Tip: schedule this script monthly (Task Scheduler / cron+pwsh / Azure Automation runbook)"
Write-Host "so orphaned resources and idle VMs get caught before they accumulate cost."
