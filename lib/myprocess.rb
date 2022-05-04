module BlackStack

  class MyProcess
    DEFAULT_MINIMUM_ENLAPSED_SECONDS = 60
    
    attr_accessor :assigned_process_changed, :assigned_division_changed, :verify_configuration
    attr_accessor :logger, :id, :worker_name, :division_name, :minimum_enlapsed_seconds, :assigned_process, :id_client, :id_division, :ws_url, :ws_port
    attr_accessor :email, :password
  
    # constructor
    def initialize(
        the_worker_name, 
        the_division_name, 
        the_minimum_enlapsed_seconds=MyProcess::DEFAULT_MINIMUM_ENLAPSED_SECONDS, 
        the_verify_configuration=true,
        the_email=nil, 
        the_password=nil
    )
      self.assigned_process_changed = false
      self.assigned_division_changed = false
      self.assigned_process = File.expand_path($0)
      self.worker_name = "#{the_worker_name}" 
      self.division_name = the_division_name
      self.minimum_enlapsed_seconds = the_minimum_enlapsed_seconds
      self.verify_configuration = the_verify_configuration
      self.email = the_email
      self.password = the_password
    end
  
    # Sube un registro a la tabla boterrorlog, con el id del worker, el proceso asignado, on id de objeto relacionado (opcional) y un screenshot (opcional). 
    #
    # uid: id de un registro en la tabla lnuser.
    # description: backtrace de la excepcion.
    #
    def notifyError(uid, description, oid=nil, screenshot_file=nil, url=nil, assigned_process=nil)
      url = !url.nil? ? url : "#{BlackStack::Pampa::api_protocol}://#{self.ws_url}:#{self.ws_port}/api1.3/bots/boterror.json"
      # subo el error
      nTries = 0
      bSuccess = false
      parsed = nil
      sError = ""
      while (nTries < 5 && bSuccess == false)
        begin
          nTries = nTries + 1
          res = BlackStack::Netting::call_post(url, # TODO: migrar a RestClient para poder hacer file upload
            'api_key' => BlackStack::Pampa::api_key, 
            'id_lnuser' => uid, 
            'id_object' => oid, 
            'worker_name' => PROCESS.fullWorkerName, 
            'process' => !assigned_process.nil? ? assigned_process : PROCESS.worker.assigned_process,
            'description' => description,
            'screenshot' => screenshot_file,
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

    # retrieves the id of the current process
    def pid()
      Process.pid.to_s
    end
  
    # Retorna un array de hashes.
    # => Cada elemento del hash tiene la forma: {:executablepath, :pid, :ppid},
    # => donde imagename es el patch completo del proceso, pid es el id del proceso
    # => y ppid es el id del proceso padre.
    def list()
      a = []
      s = `wmic process get executablepath,processid,parentprocessid`
      s.split(/\n+/).each { |e|
        aux = e.strip.scan(/^(.+)\s+(\d+)\s+(\d+)$/)[0]
        if (aux!=nil)
          if (aux.size>=3)
            a << {
              :executablepath => aux[0].strip.to_s,
              :pid => aux[2].to_s, # TODO: deberia ser aux[1], pero por algo que no entiendo ahora el pid viene en aux[2]
              :ppid => aux[1].to_s, # TODO: deberia ser aux[2], pero por algo que no entiendo ahora el pid viene en aux[1]
            }
          end
        end
      }
      a
    end
  
    # ejecuta TASKKILL /F /PID #{the_pid} y retorna el output del comando
    def self.kill(the_pid)
      system("TASKKILL /F /PID #{the_pid}")
    end
  
    # obtiene la diferencia en segundos entre la hora actual y el parametro the_start_time.
    # si la diferencia es mayor al atributo minimum_enlapsed_seconds, entonces duerme el tiempo restante.
    def doSleep(the_start_time)
      # si el proceso tardo menos del minimum_enlapsed_seconds, entonces duermo el tiempo restante
      end_time = Time.now
      elapsed_seconds = end_time - the_start_time # in seconds
      if (elapsed_seconds < self.minimum_enlapsed_seconds)
        sleep_seconds = self.minimum_enlapsed_seconds - elapsed_seconds 
        sleep(sleep_seconds)
      end
    end
  
    # This function works in windows only
    # TODO: Esta funcion no retorna la mac address completa
    # TODO: Validar que no se retorne una macaddress virtual, con todos valores en 0
    def self.macaddress()
      BlackStack::SimpleHostMonitoring.macaddress
    end
  
    def self.fullWorkerName(name)
      "#{Socket.gethostname}.#{MyProcess.macaddress}.#{name}"
    end
  
    def fullWorkerName()
      MyProcess.fullWorkerName(self.worker_name)
    end
  
    # saluda a la central
    def hello()
      # me notifico a la central. obtengo asignacion si ya la tenia
      url = "#{BlackStack::Pampa::api_url}/api1.3/pampa/hello.json"
#puts
#puts
#puts "url: #{url}"
#puts
#puts
      res = BlackStack::Netting::call_post(url, {
        'api_key' => BlackStack::Pampa::api_key, 
        'name' => self.fullWorkerName }.merge( BlackStack::RemoteHost.new.poll )
      )
      parsed = JSON.parse(res.body)
      if (parsed['status'] != BlackStack::Netting::SUCCESS)
        raise parsed['status'].to_s
      end
    end # hello()
  
    # notifico mis parametros (assigned_process, id_client) a la division asignada
    def set(new_assigned_process, new_id_client)
      if (self.ws_url.to_s.size > 0 && self.ws_port.to_s.size > 0)
        url = "#{BlackStack::Pampa::api_protocol}://#{self.ws_url.to_s}:#{self.ws_port.to_s}/api1.3/pampa/notify.json"
#puts
#puts
#puts "url: #{url}"
#puts
#puts
        res = BlackStack::Netting::call_post(url, {
          'api_key' => BlackStack::Pampa::api_key, 
          'name' => self.fullWorkerName,
          'assigned_process' => new_assigned_process,
          'id_client' => new_id_client }.merge( BlackStack::RemoteHost.new.poll )
        )
      end    
    end
  
    # obtiene sus parametros de la central
    def get()
      # me notifico a la central. obtengo asignacion que tenga
      url = "#{BlackStack::Pampa::api_url}/api1.3/pampa/get.json"
#puts
#puts
#puts "url: #{url}"
#puts
#puts
      res = BlackStack::Netting::call_post(url, {
        'api_key' => BlackStack::Pampa::api_key, 
        'name' => self.fullWorkerName }.merge( BlackStack::RemoteHost.new.poll )
      )
      parsed = JSON.parse(res.body)
      if (parsed['status'] != BlackStack::Netting::SUCCESS)
        raise parsed['status'].to_s
      else 
        if self.verify_configuration
          # si ya tenia un proceso asignado, y ahora se le asigna un nuevo proceso 
          if self.assigned_process.to_s.size > 0
            a = File.expand_path(self.assigned_process)
            b = File.expand_path(parsed['assigned_process'])
            if a != b
              self.assigned_process_changed = true
            else
              self.assigned_process_changed = false
            end
          end
    
          # si ya tenia un proceso asignado, y ahora se le asigna un nuevo proceso 
          if self.id_division.to_s.size > 0
            if self.id_division.to_guid != parsed['id_division'].to_guid
              self.assigned_division_changed = true
            else
              self.assigned_division_changed = false
            end
          end
        end # verify_configuration
              
        # si ya tenia asignada una division, entonces le notifico mi nueva configuracion
        self.set(parsed['assigned_process'], parsed['id_client'])
  
        self.id                 = parsed['id']
        self.assigned_process   = parsed['assigned_process']
        self.id_client          = parsed['id_client']
        self.id_division        = parsed['id_division']
        self.division_name      = parsed['division_name']
        self.ws_url             = parsed['ws_url']
        self.ws_port            = parsed['ws_port']      
  
        # le notifico a la nueva division asignada mi nueva configuracion
        self.set(parsed['assigned_process'], parsed['id_client'])
      end
    end # get()
  
  
    # update worker configuration in the division
    def updateWorker()
      raise "Abstract Method."
    end
  
    # ping the central database
    def ping()
      # me notifico a la central.
      url = "#{BlackStack::Pampa::api_url}/api1.3/pampa/ping.json"
      res = BlackStack::Netting::call_post(url, {
        'api_key' => BlackStack::Pampa::api_key, 
        'name' => self.fullWorkerName }.merge( BlackStack::RemoteHost.new.poll )
      )
      parsed = JSON.parse(res.body)
      if (parsed['status'] != BlackStack::Netting::SUCCESS)
        raise parsed['status'].to_s
      end
  
      # me notifico a la division.
      if (self.ws_url != nil && self.ws_port != nil)
        url = "#{BlackStack::Pampa::api_protocol}://#{self.ws_url.to_s}:#{self.ws_port.to_s}/api1.3/pampa/ping.json"
        res = BlackStack::Netting::call_post(url, {
          'api_key' => BlackStack::Pampa::api_key, 
          'name' => self.fullWorkerName }.merge( BlackStack::RemoteHost.new.poll )
        )
        parsed = JSON.parse(res.body)
        if (parsed['status'] != "success")
          raise parsed['status'].to_s
        end
      end # if
    end # ping()
  
    # se notifica al dispatcher de la division
    def notify()
      if (self.ws_url==nil || self.ws_port==nil)
        raise "Cannot notify. Worker not exists, or it has not parameters, or it is belong another client. Check your api_key, and check the name of the worker."
      end
              
      # me notifico a la division. obtengo trabajo
      url = "#{BlackStack::Pampa::api_protocol}://#{self.ws_url}:#{self.ws_port}/api1.3/pampa/notify.json"
#puts
#puts
#puts "url: #{url}"
#puts
#puts      
      res = BlackStack::Netting::call_post(url, 
        {
        'api_key' => BlackStack::Pampa::api_key, 
        'name' => self.fullWorkerName, 
        'assigned_process' => self.assigned_process,
        'id_client' => self.id_client,
        'id_division' => self.id_division }.merge( BlackStack::RemoteHost.new.poll )
      )
      parsed = JSON.parse(res.body)
      if (parsed['status'] != "success")
        raise parsed['status'].to_s
      end
    end
  
    # Get the data object of the divison assigned to this worker.
    # Needs database connections. So it's available for ChildProcess only.
    def division()
      raise "This is an abstract method."
    end
  
    # Get the data object of worker linked to this process.
    # Needs database connections. So it's available for ChildProcess only.
    def worker()
      raise "This is an abstract method."
    end
    
    # retorna true si el proceso hijo (child) esta habilitado para trabajar.
    def canRun?()
      self.assigned_process_changed == false && 
      self.assigned_division_changed == false
    end
  
    def whyCantRun()
      if self.assigned_process_changed == true
        return "Assigned process has changed." 
      elsif self.assigned_division_changed == true
        return "Assigned division has changed." 
      else
        return "unknown"
      end
    end
  
    # este metodo 
    # ejecuta el trabajo para el que fue creado el objeto.
    def process(argv)
      raise "This is an abstract method."
    end
  
    # ejecuta el proceso, en modo parent, bot o child segun la clase que se implemente.
    # en modo parent, hace un loop infinito.
    # en modo bot o child, hace un loop hasta que el metodo canRun? retorne false.
    # en modo bot o child, invoca al metodo process() en cada ciclo.
    def run()
      #raise "This is an abstract method"
    end # run
    
  end # class MyProcess

end # module BlackStack