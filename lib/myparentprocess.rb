module BlackStack

  # es un proceso sin conexion a base de datos, que itera infinitamente.
  # en cada iteracion saluda a la central (hello), obtiene parametros (get)
  class MyParentProcess < BlackStack::MyProcess
    def run()
        super
        
        # creo el objeto logger
=begin
        self.logger = BlackStack::RemoteLogger.new(
          "#{self.fullWorkerName}.log",
          BlackStack::Pampa::api_protocol, 
          BlackStack::Pampa::api_domain, 
          BlackStack::Pampa::api_port, 
          BlackStack::Pampa::api_key,
          self.id_client # ID of the client that has this thread assigned
        )
=end
        self.logger = LocalLogger.new(
          "#{self.fullWorkerName}.log"
        )

        # 
        pid = nil
        while (true)
          begin
            GC.start # 331 - avoid lack of memory
            #DB.disconnect # este proceso esta desacoplado de la conexion a la base de datos
  
            # reseteo en contador nested del logger
            self.logger.reset()
  
            # get the start time 
            start_time = Time.now
            
            # consulto a la central por la division asignada
            url = "#{BlackStack::Pampa::api_url}/api1.3/pampa/hello.json"
#puts
#puts
#puts "url: #{url}"
#puts
#puts
            logger.logs("Hello to the central... ")
            res = BlackStack::Netting::call_post(url, {
              'api_key' => BlackStack::Pampa::api_key, 
              'name' => self.fullWorkerName }.merge( BlackStack::RemoteHost.new.poll )
            )
            parsed = JSON.parse(res.body)
            if (parsed['status'] != BlackStack::Netting::SUCCESS)
              self.logger.logf("Error: " + parsed['status'].to_s)
            else
              self.logger.done
  
              url = "#{BlackStack::Pampa::api_url}/api1.3/pampa/get.json"
              logger.logs("Get worker data (#{url})... ")
              res = BlackStack::Netting::call_post(url, {
                'api_key' => BlackStack::Pampa::api_key, 
                'name' => self.fullWorkerName }.merge( BlackStack::RemoteHost.new.poll )
              )
              parsed = JSON.parse(res.body)
              if (parsed['status'] != BlackStack::Netting::SUCCESS)
                self.logger.logf("Error: " + parsed['status'].to_s)
              else
                # map response
                self.id                 = parsed['id']
                self.assigned_process   = parsed['assigned_process']
                self.id_client          = parsed['id_client']
                self.id_division        = parsed['id_division']
                self.division_name      = parsed['division_name']
                self.ws_url             = parsed['ws_url']
                self.ws_port            = parsed['ws_port']
                self.logger.logf "done (#{self.division_name})"

                # 
                self.logger.logs "Spawn child process... "    
                # lanzo el proceso
                if self.assigned_process.to_s.size > 0
                  command = "ruby #{self.assigned_process} name=#{self.worker_name} division=#{self.division_name}"
                  pid = Process.spawn(command)
                  logger.logf "done (pid=#{pid.to_s})" 
                   
                  logger.log("Wait to child process to finish.")
                  Process.wait(pid)
                else #if self.assigned_process.to_s.size == 0
                  self.logger.logf "no process assigned"
                  self.logger.logs "Notify division... "
                  if self.division_name.to_s.size == 0
                    self.logger.logf "no division assigned"                                
                  else
                    self.notify # notifico a la division
                    self.logger.done
                  end # if self.division_name.to_s.size == 0
                end # if self.assigned_process.to_s.size > 0

              end # if (parsed['status'] != "success") <-- #{BlackStack::Pampa::api_url}/api1.3/pampa/get.json
            end # if (parsed['status'] != "success") <-- #{BlackStack::Pampa::api_url}/api1.3/pampa/hello.json
  
            #  
            logger.logs "Sleep... "
            self.doSleep(start_time)
            logger.done
  
            logger.log "-------------------------------------------"
          
          rescue Interrupt => e
            logger.reset
            
            logger.log "Interrupt signal!"
    
            logger.logs "Kill process... "        
            if (pid!=nil)
              system("taskkill /im #{pid.to_s} /f /t >nul 2>&1")
            end
            logger.done
            
            logger.logs "Disconnect to Database... "
            begin
    #          DB.disconnect()
              logger.done
            rescue => e
              logger.error(e)
            end
            
            logger.log "Process is out."
            exit(0)
    
          rescue => e
            begin
              logger.log "Unhandled exception: #{e.to_s}\r\n#{e.backtrace.join("\r\n").to_s}"
              logger.logs "Sleep #{self.minimum_enlapsed_seconds.to_s} seconds... "
              sleep(self.minimum_enlapsed_seconds)
              logger.done
            rescue => e
              puts "Fatal error: #{e.to_s}"
              print "Sleep #{self.minimum_enlapsed_seconds.to_s} seconds... "
              sleep(self.minimum_enlapsed_seconds)
              puts          
            end
    
          end # rescue
  
        end # while
  
    end # def run()
    
  end # class MyParentProcess

end # module BlackStack