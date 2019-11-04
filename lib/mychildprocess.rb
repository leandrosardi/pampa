module BlackStack
  
  # es un proceso sin conexion a base de datos, que itera infinitamente.
  # en cada iteracion saluda a la central (hello), obtiene parametros (get)
  class MyChildProcess < BlackStack::MyProcess

  end # MyChildProcess

end # module BlackStack
