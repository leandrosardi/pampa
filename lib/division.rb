module BlackStack

  class Division < Sequel::Model(:division)
    include BlackStack::BaseDivision
    Division.dataset = Division.dataset.disable_insert_output
  
    def home()
      Division.where(
        :db_url=>self.db_url, 
        :db_port=>self.db_port, 
        :db_user=>self.db_user, 
        :db_password=>self.db_password, 
        :db_name=>self.db_name, 
        :app_url=>self.app_url,
        :home=>true, 
        :available=>true
      ).first
    end
  
    def self.getDefault()
      q = 
      "SELECT TOP 1 d.id AS did " +
      "FROM division d " +
      "WHERE d.name='#{SIGNUP_DIVISION}' "
      row = DB[q].first
      if (row==nil)
        return nil
      end
      return Division.where(:id=>row[:did]).first
    end
  
    # Actualiza el campo stat_name de todas las divisiones que son "gemelas" as la division pasada por parametro.
    # Ver issue #976.
    def self.updateStat(division, stat_name, date_time)
      Division.where(
        :db_url=>division.db_url,
        :db_port=>division.db_port,
        :db_user=>division.db_user,
        :db_password=>division.db_password,
      ).each { |d|
        q = "UPDATE division SET #{stat_name}='#{date_time.to_s}' WHERE id='#{d.id}'"
      }
    end
  
  end # class

end # module BlackStack