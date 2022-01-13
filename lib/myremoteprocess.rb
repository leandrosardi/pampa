module BlackStack

  # no maneja conexion a la base de datos.
  # ejecuta un loop mientras el metodo canRun? retorne true.
  class MyRemoteProcess < BlackStack::MyChildProcess
    # 
    attr_accessor :worker
      
    # update worker configuration in the division
    # TODO: deprecated
    def updateWorker()      
      # creo un remote worker que manejare en este proceso remote
      self.worker = BlackStack::RemoteWorker.new
      # me notifico a la central. obtengo asignacion si ya la tenia
      # y vuelco la configuracion al remote worker
      url = "#{BlackStack::Pampa::api_url}/api1.3/pampa/get.json"
puts
puts
puts "url: #{url}"
puts
puts      
      res = BlackStack::Netting::call_post(url, {
        'api_key' => BlackStack::Pampa::api_key, 
        'name' => self.fullWorkerName }.merge( BlackStack::RemoteHost.new.poll )
      )
      parsed = JSON.parse(res.body)
      if (parsed['status'] != BlackStack::Netting::SUCCESS)
        raise parsed['status'].to_s
      else  
        self.worker.id                  = parsed['id']
        self.worker.assigned_process    = parsed['assigned_process']
        self.worker.id_client           = parsed['id_client']
        self.worker.id_division         = parsed['id_division']
        self.worker.division_name       = parsed['division_name']
        self.worker.ws_url              = parsed['ws_url']
        self.worker.ws_port             = parsed['ws_port']
        self.worker.division            = BlackStack::RemoteDivision.new
        self.worker.division.name       = parsed['division_name']
      end
      # llamo al metodo de la clase padre que reporta la configuracion a
      # la division del worker
      self.set(parsed['assigned_process'], parsed['id_client'])
    end
  
    # 
    def run()  
=begin
        # creo el objeto logger
        self.logger = RemoteLogger.new(
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

        logger.log "Remote process is alive!"
        # actualiza parametros de la central
        logger.logs "Update from central (1-remote)... "
        self.get
        logger.done
  
        # actualizo los datos de este worker (parent process)
        logger.logs "Update worker (1-remote)... "
        self.updateWorker
        logger.done

        # actualizo los datos de este worker (parent process)
#        logger.logs "Switch logger id_client (log folder may change)... "
#        self.logger.id_client = self.id_client
#        logger.done
  
        while (self.canRun?)
  
          # reseteo en contador nested del logger
          self.logger.reset()
  
          # announcing my in the log
          logger.log "Going to Run Remote"
          logger.log "Process: #{self.assigned_process.to_s}."
          logger.log "Client: #{(self.id_client.to_s.size==0)? 'n/a' : self.id_client.to_s}."
  
          # obtengo la hora de inicio
          start_time = Time.now
  
          begin
            # libero recursos
            logger.logs "Release resources... "
            GC.start
            #DB.disconnect
            logger.done
  
            # envia senial a la central.
            # si tiene asignada una division, envia senial a la division.          
            logger.logs "Ping... "
            self.ping()
            logger.done
  
            # envia senial a la central.
            # si tiene asignada una division, envia senial a la division.          
            logger.logs "Notify to Division... "
            self.notify()
            logger.done
  
            # corro el procesamiento
            self.process(ARGV)
  
          rescue => e
            puts ""
            logger.log "Remote Process Error: " + e.to_s + "\r\n" + e.backtrace.join("\r\n").to_s      
          end
  
          # actualiza parametros de la central
          logger.logs "Update from central (2)... "
          self.get
          logger.done
  
          # actualizo los datos de este worker (parent process)
          logger.logs "Update worker (2)... "
          self.updateWorker
          logger.done
  
          # sleep
          logger.logs "Sleep... "
          self.doSleep(start_time)
          logger.done
  
          logger.log "-------------------------------------------"
  
          GC.start
          #DB.disconnect
  
        end # main while
  
        # 
        logger.log self.whyCantRun()
        
    end # run
  end # class MyRemoteProcess 

end # module BlackStack