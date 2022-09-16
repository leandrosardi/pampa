require_relative '../lib/pampa.rb'

BlackStack::Pampa.add_nodes(
  [
    {
        :name => 'node1',
        # setup SSH connection parameters
        :net_remote_ip => '127.0.0.1',  
        :ssh_username => 'ubuntu', # example: root
        :ssh_port => 22,
        :ssh_password => '2404',
        # setup max number of worker processes
        :max_workers => 10,
    },
  ]
)

BlackStack::Pampa.deploy