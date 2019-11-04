module BlackStack
  class Login < Sequel::Model(:login)
    BlackStack::Login.dataset = BlackStack::Login.dataset.disable_insert_output
    
    many_to_one :user, :class=>:'BlackStack::User', :key=>:id_user
  end
end # module BlackStack