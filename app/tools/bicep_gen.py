def generate_bicep_code(input_text: str) -> str:
    return '''
param location string = 'canadacentral'

resource db 'Microsoft.Sql/servers/databases@2022-02-01-preview' = {
  name: 'directiveiq-${uniqueString(resourceGroup().id)}'
  location: location
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 2147483648
  }
  sku: {
    name: 'GP_Gen5_2'
  }
}
'''
