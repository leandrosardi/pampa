require_relative '../lib/pampa_workers.rb'

# 
parser = BlackStack::SimpleCommandLineParser.new(
  :description => 'This command will launch a Pampa worker.', 
  :configuration => [{
    :name=>'name', 
    :mandatory=>true, 
    :description=>'Name of the worker. Note that the full-name of the worker will be composed with the host-name and the mac-address of this host too.', 
    :type=>BlackStack::SimpleCommandLineParser::STRING,
  }, {
    :name=>'division', 
    :mandatory=>true, 
    :description=>'Name of the worker. Note that the full-name of the worker will be composed with the host-name and the mac-address of this host too.', 
    :type=>BlackStack::SimpleCommandLineParser::STRING,
  }]
)

# 
BlackStack::Pampa::set_api_url({
  :api_key => 'E20CBAE0-A4D4-4161-8812-6D9FE67A2E47',
  :api_protocol => 'https',
  :api_domain => '127.0.0.1',
  :api_port => 443,
})

#
#BlackStack::Pampa::set_division_name('local')
#DB = BlackStack::Pampa::db_connection
#BlackStack::Pampa::require_db_classes

# child process definition
class MyExampleProcess < BlackStack::MyRemoteProcess  
  def process(argv)
    begin
      puts "Hello World!"
    rescue => e
      puts "ERROR: #{e.to_s}"
    end
  end # process  
end # class 

# map the name of this worker
worker_name = parser.value('name')
division_name = parser.value('division')

# create an instance of the process class
PROCESS = MyExampleProcess.new( worker_name, division_name )

# run the process
PROCESS.run()
