module BlackStack

  # Process located in the same LAN than the Database Server
  class MyLocalProcess < BlackStack::MyChildProcess
    
    # constructor
    def initialize(
      the_worker_name, 
      the_division_name, 
      the_minimum_enlapsed_seconds=BlackStack::MyProcess::DEFAULT_MINIMUM_ENLAPSED_SECONDS, 
      the_verify_configuration=true,
      the_email=nil, 
      the_password=nil
    )
      super(the_worker_name, the_division_name, the_minimum_enlapsed_seconds, the_verify_configuration, the_email, the_password)
    end
  
    def division()
      if (self.division_name != "local")
        d = BlackStack::Division.where(:name=>self.division_name).first
        if (d!=nil)
          return BlackStack::Division.where(:db_name=>d.db_name, :home=>true).first
        else
          return nil
        end
      else
        return BlackStack::Division.where(:central=>true).first
      end
    end
  
    def worker()
      BlackStack::Worker.where(:name=>self.fullWorkerName).first
    end
      
  
    # update worker configuration in the division
    def updateWorker()
      w = BlackStack::Worker.where(:name=>self.fullWorkerName).first
      if (w==nil)
        w = BlackStack::Worker.new
        w.id = guid()
        w.process = ''
        w.last_ping_time = now()
        w.name = self.fullWorkerName
        w.assigned_process = self.assigned_process
        w.id_client = self.id_client
        w.division_name = self.division_name
        w.save
      end
      if (w!=nil)
        w.assigned_process = self.assigned_process
        w.id_client = self.id_client
        w.division_name = self.division_name
        w.id_division = self.id_division
        w.save
      end
    end
  
    def run()
        super
  
        # creo el objeto logger
=begin
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

        # announcing my in the log
        logger.log "Child process is alive!"
  
        # obtengo los parametros del worker
        logger.logs "Update from central (1-local)... "
        self.get
        logger.done
  
        # actualizo los datos de este worker (parent process)
        logger.logs "Update worker (1-local)... "
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
          logger.log "Going to Run Local"
          logger.log "Process: #{self.assigned_process.to_s}."
          logger.log "Client: #{(self.id_client.to_s.size==0)? 'n/a' : self.id_client.to_s}."
  
          # obtengo la hora de inicio
          start_time = Time.now
  
          begin
            # libero recursos
            logger.logs "Release resources... "
            GC.start
            DB.disconnect
            logger.done
  
            # cargo el objeto worker
            logger.logs "Load the worker... "
            the_worker = self.worker
            logger.done
  
            # actualizo el valor del proceso que corre actualmente para este worker
            logger.logs "Update current process... "
            the_worker.process=self.assigned_process
  		      the_worker.active = true
            the_worker.save()
            logger.done
            
            logger.logs "Ping... "
            the_worker.ping()
            logger.done
            
            # corro el procesamiento
            self.process(ARGV)
            
          rescue => e
            puts ""
            logger.log "Local Process Error: " + e.to_s + "\r\n" + e.backtrace.join("\r\n").to_s
          end
  
          # obtengo los parametros del worker
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
  
          DB.disconnect
          GC.start
        end # main while
  
        # 
        logger.log "Process Finish!"
        logger.log "Finish Reason: " + self.whyCantRun.to_s
  
        #
        logger.logs "Disconnect to Database... "
        begin
          DB.disconnect()
          logger.done
        rescue => e
          logger.error(e)
        end
    end # run
    
  end # class MyLocalProcess

end # module BlackStack