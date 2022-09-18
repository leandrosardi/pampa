require_relative '../lib/pampa.rb'
require_relative '../config.rb'

BlackStack::Pampa.dispatch('../config.rb', '../worker.rb')