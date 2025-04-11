param location string = 'japanwest'
param appName string = 'directiveiq'

var storageName = toLower('${appName}storage')
var keyVaultName = toLower('${appName}-kv')
var workspaceName = toLower('${appName}-log')
var appServicePlanName = '${appName}-plan'

@secure()
param openAiApiKey string

// App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: 'B1'
    tier: 'Basic'
  }
}

// App Insights (optional for detailed logs)
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

// Azure Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: keyVaultName
  location: location
  properties: {
    tenantId: subscription().tenantId
    sku: {
      name: 'standard'
      family: 'A'
    }
    accessPolicies: [] // You can configure access policies later or use RBAC
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: true
  }
}

// Store OpenAI API Key in Key Vault
resource openAiSecret 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  name: '${keyVault.name}/OPENAI-API-KEY'
  properties: {
    value: openAiApiKey
  }
  dependsOn: [
    keyVault
  ]
}

// Azure Storage Account
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

// Web App (Linux, Python 3.11)
resource webApp 'Microsoft.Web/sites@2022-03-01' = {
  name: appName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'PYTHON|3.11'
      appSettings: [
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'OPENAI_API_KEY'
          value: '@Microsoft.KeyVault(SecretUri=${openAiSecret.properties.secretUriWithVersion})'
        }
        {
          name: 'ENV'
          value: 'production'
        }
      ]
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
  dependsOn: [
    openAiSecret
  ]
}

output endpoint string = webApp.properties.defaultHostName
