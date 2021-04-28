require_relative '../lib/pampa_workers.rb'

# parse the command line parameters
parser = BlackStack::SimpleCommandLineParser.new(
  :description => 'This command will launch a Pampa worker.', 
  :configuration => [{
    :name=>'name', 
    :mandatory=>true, 
    :description=>'Name of the worker. Note that the full-name of the worker will be composed with the host-name and the mac-address of the host where the worker is running too; so never 2 workers running in different hosts will have the same name', 
    :type=>BlackStack::SimpleCommandLineParser::STRING,
  }]
)

# setup connection to the Pampa server
BlackStack::Pampa::set_api_url({
  :api_key => '< write your API-KEY here >', # write your API-KEY here
  :api_protocol => 'https',
  :api_domain => 'connectionsphere.com', # write 127.0.0.1 if you are running Tempora in your own dev environment
  :api_port => 443,
})

# map the name of this worker
worker_name = parser.value('name')

# create an instance of the process class
PROCESS = BlackStack::MyParentProcess.new( worker_name, 'local' )

# run the process
PROCESS.run()
