require_relative '../lib/pampa.rb'

BlackStack::Pampa.set_connection_string('mysql2://root:root@localhost:3306/pampa')

BlackStack::Pampa::set_log_filename('pampa.log')

BlackStack::Pampa.add_nodes(
  [
    {
        :name => 'node1',
        # setup SSH connection parameters
        :net_remote_ip => '127.0.0.1',  
        :ssh_username => 'leandro', # example: root
        :ssh_port => 22,
        :ssh_password => '2404',
        # setup max number of worker processes
        :max_workers => 10,
    },
  ]
)

BlackStack::Pampa.deploy