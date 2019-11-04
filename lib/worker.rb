module BlackStack

  # 
  class WorkerJob < Sequel::Model(:workerjob)
     
  end

  # 
  class Worker < Sequel::Model(:worker) 
    include BlackStack::BaseWorker
    BlackStack::Worker.dataset = BlackStack::Worker.dataset.disable_insert_output
    many_to_one :division, :class=>:'BlackStack::Division', :key=>:id_division
    many_to_one :user, :class=>:'BlackStack::User', :key=>:id_user
    many_to_one :client, :class=>:'BlackStack::Client', :key=>:id_client
    many_to_one :owner, :class=>:'BlackStack::Client', :key=>:id_client_owner
    many_to_one :host, :class=>:'BlackStack::LocalHost', :key=>:id_host
    many_to_one :current_job, :class=>:'BlackStack::WorkerJob', :key=>:id_workerjob
    many_to_one :lnuser, :class=>:'BlackStack::LnUser', :key=>:id_lnuser
    many_to_one :proxy, :class=>:'BlackStack::Proxy', :key=>:id_proxy

    # Usage seconds of all the workers assigned to the client.
    # Note that the same worker may has been assigned to different clients withing the same timeframe.
    # This method will sum the seconds used by this client only
    def self.client_usage_seconds(id_client, period='M', units=1)
      row = DB[
        "select datediff(ss, dateadd(#{period}#{period}, -#{units.to_s}, getdate()), getdate()) as total_seconds, isnull(sum(datediff(ss, j.job_start_time, j.job_end_time)), 0) as used_seconds " +
        "from workerjob j with (nolock) " +
        "where j.id_client = '#{id_client}' " +
        "and j.create_time > dateadd(#{period}#{period}, -#{units.to_s}, getdate()) " +
        "and j.job_start_time is not null " +
        "and j.job_end_time is not null "
      ].first
      row[:used_seconds].to_f
    end

    # Average usage ratio of all the workers assigned to the client.
    # Note that the same worker may has been assigned to different clients withing the same timeframe.
    # This method will compute the seconds used by this client only, over the total timeframe.
    def self.client_usage_ratio(id_client, period='M', units=1)
      # 
      row = DB[
        "select count(*) as total_workers " +
        "from worker w with (nolock) " +
        "where w.id_client = '#{id_client}' "
      ].first
      t = row[:total_workers].to_f      
      
      # 
      row = DB[
        "select datediff(ss, dateadd(#{period}#{period}, -#{units.to_s}, getdate()), getdate()) as total_seconds, isnull(sum(datediff(ss, j.job_start_time, j.job_end_time)), 0) as used_seconds " +
        "from workerjob j with (nolock) " +
        "where j.id_client = '#{id_client}' " +
        "and j.create_time > dateadd(#{period}#{period}, -#{units.to_s}, getdate()) " +
        "and j.job_start_time is not null " +
        "and j.job_end_time is not null "
      ].first
      
      # 
      x = row[:used_seconds].to_f
      y = row[:total_seconds].to_f
      100.to_f * ( x / t ) / y
    end

    # Usage ratio this worker by this client.
    # Note that the same worker may has been assigned to different clients withing the same timeframe.
    # This method will sum the seconds used by this client only.
    def usage_seconds(id_client, period='M', units=1)
      row = DB[
        "select datediff(ss, dateadd(#{period}#{period}, -#{units.to_s}, getdate()), getdate()) as total_seconds, isnull(sum(datediff(ss, j.job_start_time, j.job_end_time)), 0) as used_seconds " +
        "from workerjob j with (nolock) " +
        "where j.id_client = '#{id_client}' " +
        "and j.id_worker = '#{self.id}' " + 
        "and j.create_time > dateadd(#{period}#{period}, -#{units.to_s}, getdate()) " +
        "and j.job_start_time is not null " +
        "and j.job_end_time is not null "
      ].first
      row[:used_seconds].to_f
    end

    # Usage ratio this worker by this client.
    # Note that the same worker may has been assigned to different clients withing the same timeframe.
    # This method will compute the seconds used by this client only, over the total timeframe.
    def usage_ratio(id_client, period='M', units=1)
      row = DB[
        "select datediff(ss, dateadd(#{period}#{period}, -#{units.to_s}, getdate()), getdate()) as total_seconds, isnull(sum(datediff(ss, j.job_start_time, j.job_end_time)), 0) as used_seconds " +
        "from workerjob j with (nolock) " +
        "where j.id_client = '#{id_client}' " +
        "and j.id_worker = '#{self.id}' " + 
        "and j.create_time > dateadd(#{period}#{period}, -#{units.to_s}, getdate()) " +
        "and j.job_start_time is not null " +
        "and j.job_end_time is not null "
      ].first
      x = row[:used_seconds].to_f
      y = row[:total_seconds].to_f
      100.to_f * x / y
    end
      
    # 
    def self.create(h)
      w = BlackStack::Worker.where(:name=>h['name']).first
      if w.nil?
        w = BlackStack::Worker.new
        w.id = h['id']
      end
      w.name                = h['name']
      w.process             = h['process']
      w.last_ping_time      = h['last_ping_time']
      w.assigned_process    = h['assigned_process']
      w.id_client           = h['id_client']
      w.id_division         = h['id_division']
      w.division_name       = h['division_name']
      w.public_ip_address   = h['public_ip_address']
      w.save
    end

    # 
    def to_hash
      h = {}
      h['id'] = self.id
      h['name'] = self.name
      h['process'] = self.process
      h['last_ping_time'] = self.last_ping_time
      h['assigned_process'] = self.assigned_process
      h['id_client'] = self.id_client
      h['id_division'] = self.id_division
      h['division_name'] = self.division_name
      h['public_ip_address'] = self.public_ip_address
      h
    end
  
    # Retorna true si este worker esta corriendo en nuestros propios servidores, 
    # Retorna false si este worker esta correiendo en otro host, asumiendo que es el host del cliente.
    # Comparando la pulic_ip_address del worer con la lista en BlackStack::Pampa::set_farm_external_ip_addresses.  
    def hosted?
      BlackStack::Pampa::farm_external_ip_addresses.include?(self.public_ip_address)
    end # hosted?
      
    # Retorna la cantidad de minutos desde que este worker envio una senial de vida. 
    # Este metodo se usa para saber si un worker esta activo o no.
    def last_ping_minutes()
      q = "SELECT DATEDIFF(mi, p.last_ping_time, getdate()) AS minutes FROM worker p WHERE p.id='#{self.id}'"
      return DB[q].first[:minutes].to_i
    end

    # returns true if this worker had got a ping within the last 5 minutes 
    def active?
      self.last_ping_minutes < BlackStack::BaseWorker::KEEP_ACTIVE_MINUTES
    end
  
    # envia una senial de vida a la division
    def ping()
      DB.execute("UPDATE worker SET last_ping_time=GETDATE() WHERE id='#{self.id}'")
    end
  end # class Worker
  
end # module BlackStack