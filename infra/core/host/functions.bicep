param name string
param location string = resourceGroup().location
param tags object = {}

// Reference Properties
param applicationInsightsName string
param appServicePlanId string
param storageAccountName string

// Microsoft.Web/sites Properties
param kind string = 'functionapp,workflowapp'

// Microsoft.Web/sites/config
param appSettings object = {}
param clientAffinityEnabled bool = false
param enableOryxBuild bool = contains(kind, 'linux')
param functionAppScaleLimit int = -1
param minimumElasticInstanceCount int = -1
param numberOfWorkers int = -1
param scmDoBuildDuringDeployment bool = true
param use32BitWorkerProcess bool = false
@description('ApplicationId for the App Registration')
param applicationId string
param dataverseConnectionRuntimeUrl string
param dataverseUrl string
param subnetId string
module functions 'appservice.bicep' = {
  name: '${name}-functions'
  params: {
    name: name
    location: location
    tags: tags
    applicationInsightsName: applicationInsightsName
    appServicePlanId: appServicePlanId
    appSettings: union(appSettings, {
        AzureWebJobsStorage: 'DefaultEndpointsProtocol=https;AccountName=${storage.name};AccountKey=${storage.listKeys().keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
        DATAVERSE_CONNECTION_RUNTIME_URL: dataverseConnectionRuntimeUrl
        DATAVERSE_URL: dataverseUrl
      })
    clientAffinityEnabled: clientAffinityEnabled
    enableOryxBuild: enableOryxBuild
    functionAppScaleLimit: functionAppScaleLimit
    kind: kind
    minimumElasticInstanceCount: minimumElasticInstanceCount
    numberOfWorkers: numberOfWorkers
    scmDoBuildDuringDeployment: scmDoBuildDuringDeployment
    use32BitWorkerProcess: use32BitWorkerProcess
    applicationId: applicationId
    subnetId: subnetId
  }
}

resource storage 'Microsoft.Storage/storageAccounts@2021-09-01' existing = {
  name: storageAccountName
}

output name string = functions.outputs.name
output uri string = functions.outputs.uri
output identityPrincipalId string = functions.outputs.identityPrincipalId
