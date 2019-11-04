module BlackStack
  class Role < Sequel::Model(:role)
    BlackStack::Role.dataset = BlackStack::Role.dataset.disable_insert_output
  
    ROLE_PRISMA_USER = "prisma.user"
  
  end
end # module BlackStack