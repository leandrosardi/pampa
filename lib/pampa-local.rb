require_relative './division'
require_relative './params'
require_relative './worker'
require_relative './client'
require_relative './timezone'
require_relative './user'
require_relative './login'
require_relative './role'
require_relative './userdivision'
require_relative './userrole'

# funciones auxiliares
def guid()
  DB['SELECT NEWID() AS [id]'].map(:id)[0]
end

def now()
  # La llamada a GETDATE() desde ODBC no retorna precision de milisegundos, que es necesaria para los registros de log.
  # La llamada a SYSDATETIME() retorna un valor de alta precision que no es compatible para pegar en los campos del tipo DATATIME.
  # La linea de abajo obtiene la hora en formato de SYSDATE y le trunca los ultimos digitos para hacer que el valor sea compatible con los campos DATETIME.
  (DB['SELECT SYSDATETIME() AS [now]'].map(:now)[0]).to_s[0..18]
end

def diff(unit, t0, t1)
  # La llamada a GETDATE() desde ODBC no retorna precision de milisegundos, que es necesaria para los registros de log.
  # La llamada a SYSDATETIME() retorna un valor de alta precision que no es compatible para pegar en los campos del tipo DATATIME.
  # La linea de abajo obtiene la hora en formato de SYSDATE y le trunca los ultimos digitos para hacer que el valor sea compatible con los campos DATETIME.
  (DB["SELECT DATEDIFF(#{unit}, '#{t0.to_s}', '#{t1.to_s}') AS [diff]"].map(:diff)[0]).to_i
end

def before(n) # n minutes
  DB["SELECT DATEADD(mi, -#{n.to_s}, GETDATE()) AS [now]"].map(:now)[0].to_s[0..22]
end

def monthsFromNow(n) # n months
  DB["SELECT DATEADD(mm, +#{n.to_s}, GETDATE()) AS [now]"].map(:now)[0].to_s[0..22]
end

def daysFromNow(n) # n days
  DB["SELECT DATEADD(dd, +#{n.to_s}, GETDATE()) AS [now]"].map(:now)[0].to_s[0..22]
end
