module BlackStack
  
  class Params < Sequel::Model(:params)
    Params.dataset = Params.dataset.disable_insert_output
    
    def self.getValue(s)
      param = Params.where(:name=>s).first
      if (param == nil)
        raise "Unknown parameter name (#{s.to_s})"
      else
        if param.type == PARAM_TYPE_VARCHAR
          return param.value_varchar.to_s
        elsif param.type == PARAM_TYPE_NUMERIC
          return param.value_numeric.to_i   
        elsif param.type == PARAM_TYPE_DATETIME
          return param.value_datetime
        elsif param.type == PARAM_TYPE_BIT
          return param.value_bit
        else
          raise "Unknown parameter type (#{param.type.to_s})."
        end # if param.type
      end # if (param == nil)
    end # def self.getValue
  
    def self.setValue(s, v) # TODO: Testear este metodo
      param = Params.where(:name=>s).first
      if (param == nil)
        raise "Unknown parameter name (#{s.to_s})"
      else
        if param.type == PARAM_TYPE_VARCHAR
          param.value_varchar = v
          param.save()
        elsif param.type == PARAM_TYPE_NUMERIC
          param.value_numeric = v   
          param.save()
        elsif param.type == PARAM_TYPE_DATETIME
          param.value_datetime = v
          param.save()
        elsif param.type == PARAM_TYPE_BIT
          param.value_bit = v
          param.save()
        else
          raise "Unknown parameter type (#{param.type.to_s})."
        end # if param.type
      end # if (param == nil)
    end # def self.getValue
    
  end # class

end # module BlackStack