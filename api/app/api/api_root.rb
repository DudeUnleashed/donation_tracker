class ApiRoot < Grape::API
  prefix 'api'
  
  mount UserApi
  mount AuditApi
  mount AdminApi
  mount CsvImportApi
  
end
