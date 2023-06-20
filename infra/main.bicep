targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

// Optional parameters to override the default azd resource naming conventions. Update the main.parameters.json file to provide values. e.g.,:
// "resourceGroupName": {
//      "value": "myGroupName"
// }
param applicationInsightsDashboardName string = ''
param applicationInsightsName string = ''
param appServicePlanName string = ''
param logAnalyticsName string = ''
param resourceGroupName string = ''
param storageAccountName string = ''

@description('ApplicationId for the App Registration')
param applicationId string

@secure()
param applicationSecret string

param dataverseUrl string

var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = { 'azd-env-name': environmentName }

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

// Create an App Service Plan to group applications under the same payment plan and SKU
module appServicePlan './core/host/appserviceplan.bicep' = {
  name: 'appserviceplan'
  scope: rg
  params: {
    name: !empty(appServicePlanName) ? appServicePlanName : '${abbrs.webServerFarms}${resourceToken}'
    location: location
    tags: tags
    kind: 'elastic'
    sku: {
      name: 'WS1'
      tier: 'WorkflowStandard'
      size: 'WS1'
    }
  }
}

// Backing storage for Azure functions backend API
module storage './core/storage/storage-account.bicep' = {
  name: 'storage'
  scope: rg
  params: {
    name: !empty(storageAccountName) ? storageAccountName : '${abbrs.storageStorageAccounts}${resourceToken}'
    location: location
    tags: tags
  }
}

// Monitor application with Azure Monitor
module monitoring './core/monitor/monitoring.bicep' = {
  name: 'monitoring'
  scope: rg
  params: {
    location: location
    tags: tags
    logAnalyticsName: !empty(logAnalyticsName) ? logAnalyticsName : '${abbrs.operationalInsightsWorkspaces}${resourceToken}'
    applicationInsightsName: !empty(applicationInsightsName) ? applicationInsightsName : '${abbrs.insightsComponents}${resourceToken}'
    applicationInsightsDashboardName: !empty(applicationInsightsDashboardName) ? applicationInsightsDashboardName : '${abbrs.portalDashboards}${resourceToken}'
  }
}

module dataverseConnection 'core/workflows/connections.bicep' = {
  name: 'dataverse-connection'
  scope: rg
  params: {
    applicationId: applicationId
    applicationSecret: applicationSecret
    location: location
    tags: tags
    connectionName: 'dataverse-connection'
  }
}

module functions 'core/host/functions.bicep' = {
  name: 'logic-app'
  scope: rg
  params: {
    name: '${abbrs.logicWorkflows}${environmentName}-${resourceToken}'
    location: location
    appServicePlanId: appServicePlan.outputs.id
    storageAccountName: storage.outputs.name
    applicationInsightsName: monitoring.outputs.applicationInsightsName
    tags: union(tags, { 'azd-service-name': 'api' })
    applicationId: applicationId
    dataverseConnectionRuntimeUrl: dataverseConnection.outputs.dataverseConnectionRuntimeUrl
    dataverseUrl: dataverseUrl
  }
}
module accessPolicy 'core/workflows/access.bicep' = {
  name: 'access-policy'
  scope: rg
  params: {
    accessPolicyName: functions.name
    connectionName: dataverseConnection.name
    location: location
    identityPrincipalId: functions.outputs.identityPrincipalId
  }
}
// App outputs
output APPLICATIONINSIGHTS_CONNECTION_STRING string = monitoring.outputs.applicationInsightsConnectionString
output FUNCTIONS_NAME string = functions.outputs.name
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = subscription().tenantId
