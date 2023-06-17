@description('The name of the app service resource within the current resource group scope')
param name string

@description('The app settings to be applied to the app service')
param appSettings object

@description('ApplicationId for the App Registration')
param applicationId string

resource appService 'Microsoft.Web/sites@2022-03-01' existing = {
  name: name

  resource configAppSettings 'config' = {
    name: 'appsettings'
    properties: appSettings
  }

  resource auth 'config' = {
    name: 'authsettingsV2'
    properties: {
      httpSettings: {
        requireHttps: true
        routes: {
          apiPrefix: '/.auth'
        }
        forwardProxy: {
          convention: 'NoProxy'
        }
      }
      platform: {
        enabled: true
        runtimeVersion: '~1'
      }
      globalValidation: {
        requireAuthentication: true
        unauthenticatedClientAction: 'AllowAnonymous'
        redirectToProvider: 'azureactivedirectory'
      }
      login: {
        tokenStore: {
          enabled: true
          tokenRefreshExtensionHours: 72
          fileSystem: {}
          azureBlobStorage: {}
        }
        cookieExpiration: {
          convention: 'FixedTime'
          timeToExpiration: '08:00:00'
        }
        nonce: {
          validateNonce: true
          nonceExpirationInterval: '00:05:00'
        }
      }
      identityProviders: {
        azureActiveDirectory: {
          enabled: true
          registration: {
            openIdIssuer: 'https://sts.windows.net/${subscription().tenantId}/'
            clientId: applicationId
          }
          login: {
            disableWWWAuthenticate: false
          }
          validation: {
            jwtClaimChecks: {}
            allowedAudiences: union(environment().authentication.audiences, [ applicationId ])
            defaultAuthorizationPolicy: {
              allowedApplications: [ applicationId ]
            }
          }
        }
        facebook: {
          enabled: false
        }
        gitHub: {
          enabled: false
        }
        google: {
          enabled: false
        }
        twitter: {
          enabled: false
        }
        legacyMicrosoftAccount: {
          enabled: false
        }
        apple: {
          enabled: false
        }
      }
    }
  }
}
