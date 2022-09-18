require_relative '../lib/pampa.rb'
require_relative '../config.rb'

# assign workers to each job
BlackStack::Pampa.elastic('../config.rb', '../worker.rb')

# dispatch tasks to each worker
BlackStack::Pampa.dispatch('../config.rb', '../worker.rb')