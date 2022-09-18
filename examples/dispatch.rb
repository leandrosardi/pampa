require_relative '../lib/pampa.rb'
require_relative '../config.rb'

while true
    # assign workers to each job
    BlackStack::Pampa.stretch

    # dispatch tasks to each worker
    #BlackStack::Pampa.restart

    # dispatch tasks to each worker
    BlackStack::Pampa.dispatch

    # sleep
    sleep(5)
end