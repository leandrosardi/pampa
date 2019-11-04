module BlackStack
  class UserDivision < Sequel::Model(:user_division)
    BlackStack::UserDivision.dataset = BlackStack::UserDivision.dataset.disable_insert_output
  end
end # module BlackStack
