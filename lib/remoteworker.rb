module BlackStack

  class RemoteWorker
      attr_accessor :id, :process, :last_ping_time, :name, :active, :id_division, :assigned_process, :id_client, :division_name, :ws_url, :ws_port, :division
      include BlackStack::BaseWorker
  end # Remote Worker
  
end # module BlackStack