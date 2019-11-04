require_relative '../lib/pampa_workers.rb'

# 
parser = BlackStack::SimpleCommandLineParser.new(
  :description => 'This command will launch a Pampa worker.', 
  :configuration => [{
    :name=>'name', 
    :mandatory=>true, 
    :description=>'Name of the worker. Note that the full-name of the worker will be composed with the host-name and the mac-address of this host too.', 
    :type=>BlackStack::SimpleCommandLineParser::STRING,
  }]
)

# 
BlackStack::Pampa::set_api_url({
  :api_key => '73f088c3-3e54-4e50-9778-f37a72484577',
  :api_protocol => 'https',
  :api_domain => '127.0.0.1',
  :api_port => 443,
})

# 
BlackStack::Pampa::set_db_params({
  :db_url => 'Leandro1\\DEV',
  :db_port => 1433,
  :db_name => 'kepler',
  :db_user => '',
  :db_password => '',  
})

BlackStack::Pampa::set_division_name('copernico')

DB = BlackStack::Pampa::db_connection

BlackStack::Pampa::require_db_classes

# child process definition
class MyExampleProcess < BlackStack::MyLocalProcess  
  def process(argv)
    begin
      puts "Hello World!"
    rescue => e
      puts "ERROR: #{e.to_s}"
    end
  end # process  
end # class 

# create an instance of the process class

worker_name = 'my_worker'
division_name = 'local'

PROCESS = MyExampleProcess.new(worker_name, division_name)

# run the process
PROCESS.run()
