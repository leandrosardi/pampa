module BlackStack
  class UserRole < Sequel::Model(:user_role)
    BlackStack::UserRole.dataset = BlackStack::UserRole.dataset.disable_insert_output
    many_to_one :user, :class=>:'BlackStack::User', :key=>:id_user
    many_to_one :role, :class=>:'BlackStack::Role', :key=>:id_role
  
  end
end # module BlackStack