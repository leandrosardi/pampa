require_relative '../lib/pampa.rb'
require_relative '../config.rb'

BlackStack::Pampa.elastic('../config.rb', '../worker.rb')