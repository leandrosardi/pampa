# this process is launched from a Pampa worker.

require_relative '../lib/pampa_workers.rb'

# parse the command line parameters
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
    :description=>'Name of the division where this worker is assigned. For more information about divisions, please refer to https://github.com/leandrosardi/tempora#1-architecuture.', 
    :type=>BlackStack::SimpleCommandLineParser::STRING,
  }]
)

# setup connection to the Pampa server
BlackStack::Pampa::set_api_url({
  :api_key => '56D608FC-645D-4A7B-9C38-94C853CADD5A', # write your API-KEY here
  :api_protocol => 'https',
  :api_domain => 'connectionsphere.com', # write 127.0.0.1 if you are running Tempora in your own dev environment
  :api_port => 443,
})

# child process definition
class MyExampleProcess < BlackStack::MyRemoteProcess  
  def process(argv)
    begin
      puts "Hello ConnectionSphere.com!"
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
