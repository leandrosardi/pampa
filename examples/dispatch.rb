require_relative '../lib/pampa.rb'
require_relative '../config.rb'

l = BlackStack::Pampa.logger

while true
    # assign workers to each job
    l.logs 'Assigning workers to jobs... '
    BlackStack::Pampa.stretch
    l.done

    # relaunch expired tasks
    l.logs 'Relaunching expired tasks... '
    #BlackStack::Pampa.relaunch
    l.done

    # dispatch tasks to each worker
    l.logs 'Dispatching tasks to workers... '
    BlackStack::Pampa.dispatch
    l.done

    # sleep
    sleep(5)
end