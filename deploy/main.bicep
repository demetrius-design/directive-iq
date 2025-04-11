param location string = 'japanwest'
param appName string = 'directiveiq'

@secure()
param openAiApiKey string

var storageName = toLower('${appName}storage')
var keyVaultName = toLower('${appName}-kv')
var workspaceName = toLower('${appName}-log')
var appServicePlanName = '${appName}-plan'

resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: 'B1'
    tier: 'Basic'
  }
}

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: workspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: keyVaultName
  location: location
  properties: {
    tenantId: subscription().tenantId
    sku: {
      name: 'standard'
      family: 'A'
    }
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: true
  }
}

resource openAiSecret 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  name: '${keyVault.name}/AZURE-OPENAI-API-KEY'
  properties: {
    value: openAiApiKey
  }
  dependsOn: [
    keyVault
  ]
}

resource storage 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
  }
}

resource webApp 'Microsoft.Web/sites@2022-03-01' = {
  name: appName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'PYTHON|3.11'
      appSettings: [
        {
          name: 'ENV'
          value: 'production'
        }
        {
          name: 'AZURE_OPENAI_API_KEY'
          value: '@Microsoft.KeyVault(SecretUri=${openAiSecret.properties.secretUriWithVersion})'
        }
        {
          name: 'AZURE_OPENAI_ENDPOINT'
          value: 'https://your-resource-name.openai.azure.com/'  // Replace with your actual endpoint
        }
        {
          name: 'AZURE_OPENAI_DEPLOYMENT'
          value: 'gpt-4-deployment'  // Replace with your actual deployment name
        }
        {
          name: 'AZURE_OPENAI_VERSION'
          value: '2023-07-01-preview'
        }
      ]
    }
  }
  dependsOn: [
    openAiSecret
  ]
}

output endpoint string = webApp.properties.defaultHostName
