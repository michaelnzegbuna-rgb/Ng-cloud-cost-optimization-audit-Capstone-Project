// main-after.bicep
// RIGHTSIZED version of the same environment, matched to observed
// utilization from Azure Monitor + Azure Advisor recommendations.
//
// Deploy with:
//   az deployment group create \
//     --resource-group rg-cost-audit-demo \
//     --template-file infra/main-after.bicep \
//     --parameters namePrefix=ngstartup location=southafricanorth \
//     --parameters adminPassword="<a-strong-password>"

@description('Prefix used for all resource names')
param namePrefix string = 'ngstartup'

@description('Azure region to deploy into')
param location string = 'southafricanorth'

@description('Admin password for the VM')
@secure()
param adminPassword string

var vmName = '${namePrefix}-app-vm'
var appServicePlanName = '${namePrefix}-plan'
var webAppName = '${namePrefix}-web-${uniqueString(resourceGroup().id)}'
var sqlServerName = '${namePrefix}-sql-${uniqueString(resourceGroup().id)}'
var sqlDbName = '${namePrefix}-db'
var storageAccountName = toLower('${namePrefix}st${uniqueString(resourceGroup().id)}')
var vnetName = '${namePrefix}-vnet'
var nicName = '${namePrefix}-nic'
var pipName = '${namePrefix}-pip'

// ---- Networking (unchanged - no cost issue here) ----
resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: { addressPrefixes: ['10.10.0.0/16'] }
    subnets: [
      { name: 'default', properties: { addressPrefix: '10.10.0.0/24' } }
    ]
  }
}

resource pip 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: pipName
  location: location
  sku: { name: 'Standard' }
  properties: { publicIPAllocationMethod: 'Static' }
}

resource nic 'Microsoft.Network/networkInterfaces@2023-05-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: { id: '${vnet.id}/subnets/default' }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: { id: pip.id }
        }
      }
    ]
  }
}

// ---- FIX #1: Standard_B2s (burstable, 2 vCPU/4GB) on Standard SSD ----
resource vm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: { vmSize: 'Standard_B2s' }
    osProfile: {
      computerName: vmName
      adminUsername: 'azureuser'
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: { storageAccountType: 'StandardSSD_LRS' }
      }
    }
    networkProfile: {
      networkInterfaces: [ { id: nic.id } ]
    }
  }
}

// Auto-shutdown schedule: 22:00 - 06:00 West Central Africa Time
resource autoShutdown 'Microsoft.DevTestLab/schedules@2018-09-15' = {
  name: 'shutdown-computevm-${vmName}'
  location: location
  properties: {
    status: 'Enabled'
    taskType: 'ComputeVmShutdownTask'
    dailyRecurrence: { time: '2200' }
    timeZoneId: 'W. Central Africa Standard Time'
    targetResourceId: vm.id
  }
}

// ---- FIX #2: App Service Plan downgraded to B1 (Basic) ----
resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: appServicePlanName
  location: location
  sku: { name: 'B1', tier: 'Basic' }
  properties: { reserved: true }
}

resource webApp 'Microsoft.Web/sites@2023-01-01' = {
  name: webAppName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: { linuxFxVersion: 'NODE|18-lts' }
  }
}

// ---- FIX #3: SQL Database moved to Serverless, auto-pause after 60 min ----
resource sqlServer 'Microsoft.Sql/servers@2023-05-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: 'sqladmin'
    administratorLoginPassword: adminPassword
  }
}

resource sqlDb 'Microsoft.Sql/servers/databases@2023-05-01-preview' = {
  parent: sqlServer
  name: sqlDbName
  location: location
  sku: { name: 'GP_S_Gen5', tier: 'GeneralPurpose', family: 'Gen5', capacity: 1 }
  properties: {
    autoPauseDelay: 60
    minCapacity: json('0.5')
  }
}

// ---- FIX #4: Storage Account with lifecycle policy (see storage-lifecycle-policy.json) ----
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: { name: 'Standard_LRS' }
  properties: { accessTier: 'Hot' }
}

// ---- FIX #5: orphaned disk + public IP simply not created here ----
// (they were deleted rather than redeployed - see scripts/02-cleanup-orphans.sh)

output vmName string = vm.name
output webAppUrl string = 'https://${webApp.properties.defaultHostName}'
output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName
output storageAccountName string = storageAccount.name
