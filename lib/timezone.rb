module BlackStack
  class Timezone < Sequel::Model(:timezone)
    BlackStack::Timezone.dataset = BlackStack::Timezone.dataset.disable_insert_output
  
    # Recibe un string con formato "+HH:MM".
    # Retorna la cantidad de horas como un numero real, con decimales.
    def self.descToFloat(s)
      sign = s[0]
      if (sign=="+")
        n = 1.0
      else
        n = -1.0
      end
      hours = s[1..2]
      minutes = s[4..5]
      int_part = hours.to_f
      dec_part = minutes.to_f / 60.00
      ret = n*(int_part + dec_part)    
      return ret.to_f 
    end
  
    # Recibe la cantidad de horas como un numero real, con decimales.
    # Retorna un string con formato "+HH:MM".
    def self.floatToDesc(x)
      int_part = x.to_i
      dec_part = (x-int_part.to_f).round(2).abs
      hours = int_part
      minutes = (dec_part * 60.00).to_i    
      if (hours<0)
        desc = "%03d" % hours 
      else
        desc = "+" + "%02d" % hours
      end
      desc += ":" + "%02d" % minutes
      return desc
    end
  
    # Example: '-03:00'
    # Example: ' 08:00'
    def self.getDatabaseOffset()
      dbtime = DB["select SYSDATETIMEOFFSET() AS o"].first[:o].to_s
  #puts ""
  #puts ""
  #puts "dbtime:#{dbtime.to_s}:."
  #puts ""
  #puts ""
      ret = "#{dbtime[-5..-3]}:#{dbtime[-2..-1]}" 
      ret[0] = '+' if ret[0]!='-'
  #puts ""
  #puts ""
  #puts "dbtime:#{ret.to_s}:."
  #puts ""
  #puts ""
      return ret
    end
  
    # Convierte el atributo offset en un string con formato de hora.
    # Ejemplos: 5.0 => 05:00, 5.5 => 05:30, -5.75 => -05:45   
    def offsetDescription()
      return BlackStack::Timezone.floatToDesc(self.offset.to_f)
    end
    
    # Convierte una hora almacenada en el servidor de bases de datos, a la hora en esta zona horaria.
    # Recibe un string con formato "+HH:MM".
    # Retorna un string con formato "+HH:MM".
    def convertFromThisTimeZoneToDatabaseTime(s_time_in_client_timezone)
      f_time_in_client_timezone = BlackStack::Timezone.descToFloat(s_time_in_client_timezone)
      s = BlackStack::Timezone.getDatabaseOffset()
      x = BlackStack::Timezone.descToFloat(s) # database offset
      y = self.offset # client offset
      z = y - x 
      return BlackStack::Timezone.floatToDesc((f_time_in_client_timezone.to_f + z.to_f).modulo(24))
    end
  
    # Convierte una hora almacenada en el servidor de bases de datos, a la hora en esta zona horaria.
    # Recibe un string con formato "+HH:MM".
    # Retorna un string con formato "+HH:MM".
    def convertFromDatabaseTimeToThisTimeZone(s_time_in_database)
      f_time_in_database = BlackStack::Timezone.descToFloat(s_time_in_database)
      s = BlackStack::Timezone.getDatabaseOffset()
      x = BlackStack::Timezone.descToFloat(s) # database offset
      y = self.offset # client offset
      z = y - x 
      return BlackStack::Timezone.floatToDesc((f_time_in_database.to_f - z.to_f).modulo(24))
    end
  
    # Convierte una fecha-hora almacenada en el servidor de bases de datos, a la hora en esta zona horaria.
    # Recibe un string con formato "YYYY-MM-DD HH:MM:SS".
    # Retorna un string con formato "YYYY-MM-DD HH:MM:SS".
    def convertFromDatabaseDateTimeToThisTimeZone(s_datetime_in_database)
      s = BlackStack::Timezone.getDatabaseOffset() # Example: '-03:00'
  #puts ""
  #puts ""
  #puts "s:#{s.to_s}:."
  #puts ""
  #puts ""
      x = BlackStack::Timezone.descToFloat(s) # database offset. Number of hours, with decimals
  #puts ""
  #puts ""
  #puts "x:#{x.to_s}:."
  #puts ""
  #puts ""
      y = self.offset # client offset
  #puts ""
  #puts ""
  #puts "y:#{y.to_s}:."
  #puts ""
  #puts ""
      z = y - x 
  #puts ""
  #puts ""
  #puts "z:#{z.to_s}:."
  #puts ""
  #puts ""
      ret = DB["SELECT DATEADD(HH, #{z.to_s}, '#{s_datetime_in_database}') AS o"].first[:o].to_s[0..18]
  #puts ""
  #puts ""
  #puts "convertFromDatabaseDateTimeToThisTimeZone:#{ret}:."
  #puts ""
  #puts ""
  
      return ret
    end
    
    # 
    def get_now()
      datetime1 = DB["SELECT GETDATE() AS o"].first[:o].to_s[0..18]
      datetime2 = self.convertFromDatabaseDateTimeToThisTimeZone(datetime1)
  #puts ""
  #puts ""
  #puts "timezone:#{self.large_description}:."
  #puts "datetime1:#{datetime1}:."
  #puts "datetime2:#{datetime2}:."
  #puts ""
  #puts ""
      yy = datetime2[0..3] # yyyy-mm-dd hh:mi:ss
      mm = datetime2[5..6]
      dd = datetime2[8..9]
      hh = datetime2[11..12]
      mi = datetime2[14..15]
      ss = datetime2[17..18]
  #puts ""
  #puts ""
  #puts "get_now:#{yy}-#{mm}-#{dd} #{hh}:#{mi}:#{ss}:."
  #puts ""
  #puts ""
      return Time.new(yy,mm,dd,hh,mi,ss)
    end
    
  end
end # module BlackStack