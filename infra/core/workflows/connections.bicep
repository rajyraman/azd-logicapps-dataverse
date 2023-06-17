param connectionName string
param location string = resourceGroup().location
param tags object = {}
param applicationId string
@secure()
param applicationSecret string

resource dataverseConnection 'Microsoft.Web/connections@2016-06-01' = {
  name: connectionName
  location: location
  tags: tags
  kind: 'V2'
  properties: {
    api: {
      id: 'subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/commondataservice'
    }
    displayName: connectionName
    parameterValues: {
      'token:clientId': applicationId
      'token:TenantId': subscription().tenantId
      'token:grantType': 'client_credentials'
      'token:clientSecret': applicationSecret
    }
  }
}

output dataverseConnectionRuntimeUrl string = dataverseConnection.properties.connectionRuntimeUrl
