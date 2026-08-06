// main-before.bicep
// Deliberately OVER-PROVISIONED "startup-like" baseline environment.
// Mirrors common early-stage Nigerian startup mistakes so the audit
// has something real to measure and rightsize.
//
// Deploy with:
//   az group create --name rg-cost-audit-demo --location southafricanorth
//   az deployment group create \
//     --resource-group rg-cost-audit-demo \
//     --template-file infra/main-before.bicep \
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
var orphanDiskName = '${namePrefix}-orphan-disk'
var orphanPipName = '${namePrefix}-orphan-pip'

// ---- Networking ----
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

// ---- ISSUE #1: oversized VM (Standard_D4s_v3, 4 vCPU/16GB) on Premium SSD ----
resource vm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: { vmSize: 'Standard_D4s_v3' }
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
        managedDisk: { storageAccountType: 'Premium_LRS' } // over-provisioned tier
      }
    }
    networkProfile: {
      networkInterfaces: [ { id: nic.id } ]
    }
  }
}

// ---- ISSUE #2: App Service Plan on P1v2 (Premium v2), running 24/7 ----
resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: appServicePlanName
  location: location
  sku: { name: 'P1v2', tier: 'PremiumV2' }
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

// ---- ISSUE #3: SQL Database on Standard S3 (100 DTU) ----
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
  sku: { name: 'S3', tier: 'Standard', capacity: 100 }
}

// ---- ISSUE #4: Storage Account defaulting to Hot tier for everything ----
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: { name: 'Standard_LRS' }
  properties: { accessTier: 'Hot' }
}

// ---- ISSUE #5: Orphaned leftovers simulating forgotten test resources ----
resource orphanDisk 'Microsoft.Compute/disks@2023-04-02' = {
  name: orphanDiskName
  location: location
  sku: { name: 'Premium_LRS' }
  properties: {
    creationData: { createOption: 'Empty' }
    diskSizeGB: 64
  }
}

resource orphanPip 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: orphanPipName
  location: location
  sku: { name: 'Standard' }
  properties: { publicIPAllocationMethod: 'Static' }
}

output vmName string = vm.name
output webAppUrl string = 'https://${webApp.properties.defaultHostName}'
output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName
output storageAccountName string = storageAccount.name
