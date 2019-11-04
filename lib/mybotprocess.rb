module BlackStack

  # clase de base para todos los bots ejecuten acciones con una cuenta de LinkedIn, Facebook, Twitter, etc.
  class MyBotProcess < BlackStack::MyRemoteProcess
    attr_accessor :username, :login_verifications, :run_once   
  
    # constructor
    def initialize(
      the_worker_name, 
      the_division_name, 
      the_minimum_enlapsed_seconds=MyProcess::DEFAULT_MINIMUM_ENLAPSED_SECONDS, 
      the_verify_configuration=true,
      the_email=nil, 
      the_password=nil
    )
      super(the_worker_name, the_division_name, the_minimum_enlapsed_seconds, the_verify_configuration, the_email, the_password)    
      self.assigned_process = File.expand_path($0)
      self.worker_name = "#{the_worker_name}" 
      self.division_name = the_division_name
      self.minimum_enlapsed_seconds = the_minimum_enlapsed_seconds
      
      # algunas clases como CreateLnUserProcess o RepairLnUserProcess, trabajan unicamente con el username especificado en este atributo, llamando al access point get_lnuser_by_username.
      # si este atributo es nil, entonces la clase pide un lnuser a la division, llamando al access point get_lnuser.
      self.username = nil
      
      # al correr un proceso sin supervision, el login require verificaciones automaticas que demoran tiempo (account blocingcaptcha, sms pin, bloqueo)
      # las verificaciones consument tiempo.
      # si este proceso se corre de forma supevisada, las verificaciones se pueden deshabilitar
      self.login_verifications = true
  
      # al correr sin supervision, el proceso de terminar un un paquete de procesamiento y comenzar con otro, funcionando en un loop infinito.
      # si este proceso se corre de forma supevisada, se desa correr el procesamiento una unica vez.
      # cuando se activa este flag, generalmente se setea el atributo self.username tambien. 
      self.run_once = false
    end
  
    # returns a hash with the parameters of a lnuser
    # raises an exception if it could not get a lnuser, or if ocurrs any other problem
    def getLnUserByUsername(username)
      nTries = 0
      parsed = nil
      lnuser = nil # hash
      bSuccess = false
      sError = ""
      while (nTries < 5 && bSuccess == false)
        begin
          nTries = nTries + 1
          url = "#{BlackStack::Pampa::api_protocol}://#{self.ws_url}:#{self.ws_port}/api1.3/pampa/login.lnuser/get_lnuser.json"
          res = BlackStack::Netting::call_post(url, {'api_key' => BlackStack::Pampa::api_key, 'username' => username.encode("UTF-8")})
          parsed = JSON.parse(res.body)        
          if (parsed['status']=='success')
            lnuser = parsed
            bSuccess = true
          else
            sError = parsed['status']
          end
        rescue Errno::ECONNREFUSED => e
          sError = "Errno::ECONNREFUSED:" + e.to_console
        rescue => e2
          sError = "Exception: " + e2.to_console
        end
      end # while
  
      if (bSuccess==false)
        raise BlackStack::Netting::ApiCallException.new(sError)
      end
  
      return lnuser
    end # getLnUser()
  
    # returns a hash with the parameters of a lnuser
    # raises an exception if it could not get a lnuser, or if ocurrs any other problem
    def getLnUser(workflow_name='incrawl.lnsearchvariation')
      nTries = 0
      parsed = nil
      lnuser = nil # hash
      bSuccess = false
      sError = ""
      while (nTries < 5 && bSuccess == false)
        begin
          nTries = nTries + 1
          url = "#{BlackStack::Pampa::api_protocol}://#{self.ws_url}:#{self.ws_port}/api1.3/pampa/#{workflow_name}/get_lnuser.json"
          res = BlackStack::Netting::call_post(url, {'api_key' => BlackStack::Pampa::api_key, 'name' => self.fullWorkerName})
          parsed = JSON.parse(res.body)        
          if (parsed['status']=='success')
            lnuser = parsed
            bSuccess = true
          else
            sError = parsed['status']
          end
        rescue Errno::ECONNREFUSED => e
          sError = "Errno::ECONNREFUSED:" + e.to_console
        rescue => e2
          sError = "Exception:" + e2.to_console
        end
      end # while
  
      if (bSuccess==false)
        raise BlackStack::Netting::ApiCallException.new(sError)
      end
  
      return lnuser
    end # getLnUser()

    #
    def notifyInbox(lnuser, conv)
      conv[:chats].each { |chat|        
        # armo URL de notificacion
        # se usa URI.encode para codificar caracteres no-ascii en los mensajes
        url = 
          "#{BlackStack::Pampa::api_protocol}://#{self.ws_url}:#{self.ws_port}/api1.3/pampa/scrape.inbox/notify_lnchat.json?" +
          "api_key=#{BlackStack::Pampa::api_key}&" +
          "profile_code=#{URI.escape(conv[:profile_code])}&" +
          "profile_name=#{URI.escape(conv[:profile_name])}&" +
          "profile_headline=#{URI.escape(conv[:profile_headline])}&" +
          "first=#{URI.escape(conv[:first])}&" +
          "position=#{chat[:position].to_s}&" +
          "uid=#{lnuser['id']}&" +
          "sender_name=#{URI.escape(chat[:sender_name])}&" +
          "body=#{URI.escape(chat[:body])}&" 
#puts ""
#puts "url:#{url}:."
#puts ""
        # HELP: File.open('./output3.txt', 'a') { |file| file.write(url + "\r\n") }
  
        # push the chat
        uri = URI.parse(url.to_s)
        req = Net::HTTP::Get.new(uri.to_s)
        res = Net::HTTP.start(uri.host, uri.port, :use_ssl => true, :verify_mode => OpenSSL::SSL::VERIFY_NONE) {|http|
          http.request(req)
        }
        parsed = JSON.parse(res.body)
        raise "error uploading chat: #{parsed['status']}" if parsed['status'] != 'success'
      } # conv[:chats].each
    end

    #  
    def notifyLnUserUrl(id_lnuser, profile_url)
      nTries = 0
      parsed = nil
      bSuccess = false
      sError = ""
      while (nTries < 5 && bSuccess == false)
        begin
          nTries = nTries + 1
          url = "#{BlackStack::Pampa::api_protocol}://#{self.ws_url}:#{self.ws_port}/api1.3/pampa/login.lnuser/notify_url.json"
          res = BlackStack::Netting::call_post(url,
            {:api_key => BlackStack::Pampa::api_key,
            'id_lnuser' => id_lnuser,
            'url' => profile_url,}
          )
          parsed = JSON.parse(res.body)
          
          if (parsed['status']=='success')
            bSuccess = true
          else
            sError = parsed['status']
          end
        rescue Errno::ECONNREFUSED => e
          sError = "Errno::ECONNREFUSED:" + e.to_console
        rescue => e2
          sError = "Exception:" + e2.to_console
        end
      end # while 
  
      if (bSuccess==false)
        raise "#{sError}"
      end
    end # notifyLnUserStatus
  
    #  
    def notifyLnUserStatus(id_lnuser, status, workflow_name='incrawl.lnsearchvariation')
      nTries = 0
      parsed = nil
      bSuccess = false
      sError = ""
      while (nTries < 5 && bSuccess == false)
        begin
          nTries = nTries + 1
          url = "#{BlackStack::Pampa::api_protocol}://#{self.ws_url}:#{self.ws_port}/api1.3/pampa/#{workflow_name}/notify_lnuser_status.json"
          res = BlackStack::Netting::call_post(url,
            {'api_key' => BlackStack::Pampa::api_key, 
            'id_lnuser' => id_lnuser,
            'status' => status,}
          )
          parsed = JSON.parse(res.body)
          
          if (parsed['status']=='success')
            bSuccess = true
          else
            sError = parsed['status']
          end
        rescue Errno::ECONNREFUSED => e
          sError = "Errno::ECONNREFUSED:" + e.to_console
        rescue => e2
          sError = "Exception:" + e2.to_console
        end
      end # while 
  
      if (bSuccess==false)
        raise "#{sError}"
      end
  
    end # notifyLnUserStatus
  
    #  
    def notifyLnUserActivity(id_lnuser, code, workflow_name='incrawl.lnsearchvariation')
      nTries = 0
      parsed = nil
      bSuccess = false
      sError = ""
      while (nTries < 5 && bSuccess == false)
        begin
          nTries = nTries + 1
          url = "#{BlackStack::Pampa::api_protocol}://#{self.ws_url}:#{self.ws_port}/api1.3/pampa/#{workflow_name}/notify_lnuser_activity.json"
          res = BlackStack::Netting::call_post(url,
            {'api_key' => BlackStack::Pampa::api_key, 
            'id_lnuser' => id_lnuser,
            'code' => code,}
          )
          parsed = JSON.parse(res.body)
          
          if (parsed['status']=='success')
            bSuccess = true
          else
            sError = parsed['status']
          end
        rescue Errno::ECONNREFUSED => e
          sError = "Errno::ECONNREFUSED:" + e.to_console
        rescue => e2
          sError = "Exception:" + e2.to_console
        end
      end # while 
  
      if (bSuccess==false)
        raise "#{sError}"
      end
    end # notifyLnUserStatus
  
    # Toma una captura del browser.
    # Sube un registro a la tabla boterrorlog, con el id del worker, el proceso asinado, y el screenshot. 
    #
    # uid: id de un registro en la tabla lnuser.
    # description: backtrace de la excepcion.
    #
    def notifyError(uid, description, oid=nil)
      # tomo captura de pantalla
      file = nil
=begin # TODO: habilitar esto cuando se migre a RestClient en vez de CallPost
      begin
        screenshot_filename = "./error.png" # TODO: colocar un nombre unico formado por por el fullname del worker, y la fecha-hora.
        BrowserFactory.screenshot screenshot_filename
        file = File.new(screenshot_filename, "rb")
      rescue => e
  puts "Screenshot Error: #{e.to_s}"
        file = nil
      end
=end
  #puts ""
  #puts "id_worker:#{PROCESS.worker.id}"
  #puts "worker_name:#{PROCESS.fullWorkerName}"
  #puts "process:#{PROCESS.worker.assigned_process}"
  #puts ""
      # subo el error
      nTries = 0
      bSuccess = false
      parsed = nil
      sError = ""
      while (nTries < 5 && bSuccess == false)
        begin
          nTries = nTries + 1
          url = "#{BlackStack::Pampa::api_protocol}://#{self.ws_url}:#{self.ws_port}/api1.3/pampa/boterror.json"
          res = BlackStack::Netting::call_post(url, # TODO: migrar a RestClient para poder hacer file upload
            'api_key' => BlackStack::Pampa::api_key, 
            'id_lnuser' => uid, 
            'id_object' => oid, 
            'worker_name' => PROCESS.fullWorkerName, 
            'process' => PROCESS.worker.assigned_process,
            'description' => description,
            'screenshot' => file,
          )
          parsed = JSON.parse(res.body)
          if (parsed['status']=='success')
            bSuccess = true
          else
            sError = parsed['status']
          end
        rescue Errno::ECONNREFUSED => e
          sError = "Errno::ECONNREFUSED:" + e.to_console
        rescue => e2
          sError = "Exception:" + e2.to_console
        end
      end # while
  
      if (bSuccess==false)
        raise "#{sError}"
      end
    end
  
    #  
    def isLnUserAvailable(id_lnuser, need_sales_navigator=false, workflow_name='incrawl.lnsearchvariation')
      nTries = 0
      parsed = nil
      bSuccess = false
      sError = ""
      ret = false
      
      while (nTries < 5 && bSuccess == false)
        begin
          nTries = nTries + 1
          url = "#{BlackStack::Pampa::api_protocol}://#{self.ws_url}:#{self.ws_port}/api1.3/pampa/#{workflow_name}/is_lnuser_available.json"
          res = BlackStack::Netting::call_post(url,
            {'api_key' => BlackStack::Pampa::api_key, 
            'id_lnuser' => id_lnuser,
            'need_sales_navigator' => need_sales_navigator,}
          )
          parsed = JSON.parse(res.body)
          
          if (parsed['status']=='success')
            bSuccess = true
            ret = parsed['value']
          else
            sError = parsed['status']
          end
        rescue Errno::ECONNREFUSED => e
          sError = "Errno::ECONNREFUSED:" + e.to_s
        rescue => e2
          sError = "Alghoritm Exception" + e2.to_s + '\r\n' + e2.backtrace.join("\r\n").to_s
        end
      end # while 
  
      if (bSuccess==false)
        raise "#{sError}"
      end
      
      return ret
    end # isLnUserAvailable
  
    # TODO: deprecated
    def releaseLnUser(id_lnuser, workflow_name='incrawl.lnsearchvariation')
=begin
      nTries = 0
      parsed = nil
      bSuccess = false
      sError = ""
      ret = false
      
      while (nTries < 5 && bSuccess == false)
        begin
          nTries = nTries + 1
          url = "#{BlackStack::Pampa::api_protocol}://#{self.ws_url}:#{self.ws_port}/api1.3/pampa/#{workflow_name}/release_lnuser.json"
          res = BlackStack::Netting::call_post(url,
            {'api_key' => BlackStack::Pampa::api_key, 'id_lnuser' => id_lnuser,}
          )
          parsed = JSON.parse(res.body)
          
          if (parsed['status']=='success')
            bSuccess = true
            ret = parsed['value']
          else
            sError = parsed['status']
          end
        rescue Errno::ECONNREFUSED => e
          sError = "Errno::ECONNREFUSED:" + e.to_console
        rescue => e2
          sError = "Exception:" + e2.to_console
        end
      end # while 
  
      if (bSuccess==false)
        raise "#{sError}"
      end
      
      return ret
=end
    end # isLnUserAvailable
  
  end # class MyBotProcess

end # module BlackStack