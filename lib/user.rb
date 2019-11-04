module BlackStack
  class User < Sequel::Model(:user)
    BlackStack::User.dataset = BlackStack::User.dataset.disable_insert_output
    many_to_one :client, :class=>:'BlackStack::Client', :key=>:id_client
    one_to_many :user_roles, :class=>:'BlackStack::UserRole', :key=>:id_user
  
  # TODO: agregar todos los arrays de un usuario
  # => one_to_many :searches, :class=>:Search, :key=>:id_user
  # => one_to_many :emlist, :class=>:EmList, :key=>:id_user
  # => one_to_many :emlist, :class=>:EmList, :key=>:id_user
  # => etc.
  
    # retorna la primera division habilitada a la que pertenezca este usuario
    def division
      row = DB[
      "SELECT d.id " +
      "FROM division d WITH (NOLOCK) " +
      "JOIN user_division ud WITH (NOLOCK) ON (d.id=ud.id_division AND ud.id_user='#{self.id}') " +
      "WHERE ISNULL(d.available,0) = 1 "
      ].first
      return nil if row.nil?
      return BlackStack::Division.where(:id=>row[:id]).first if !row.nil?
    end  
  end # class User
end # module BlackStack
