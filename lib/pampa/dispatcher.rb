# Pampa Dispatcher
# Copyright (C) 2022 ExpandedVenture, LLC.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# You may not use this file except in compliance with the License.
#
# Authors: Leandro Daniel Sardi (https://github.com/leandrosardi)
#

# load gem and connect database
require 'pampa'
DB = BlackStack::PostgreSQL::connect

# parse command line parameters
PARSER = BlackStack::SimpleCommandLineParser.new(
    :description => 'This script starts an infinite loop. Each loop will look for a task to perform. Must be a delay between each loop.',
    :configuration => [{
        :name=>'delay',
        :mandatory=>false,
        :default=>10, # 5 minutes 
        :description=>'Minimum delay between loops. A minimum of 10 seconds is recommended, in order to don\'t hard the database server. Default is 30 seconds.', 
        :type=>BlackStack::SimpleCommandLineParser::INT,
    }]
)

# use the pampa logger
l = BlackStack::Pampa.logger

# loop
while true
    # get the start loop time
    l.logs 'Starting loop... '
    start = Time.now()
    l.done        

    begin
        # assign workers to each job
        l.logs 'Stretching clusters... '
        BlackStack::Pampa.stretch
        l.done

        # relaunch expired tasks
        l.logs 'Relaunching expired tasks... '
        BlackStack::Pampa.relaunch
        l.done

        # dispatch tasks to each worker
        l.logs 'Dispatching tasks to workers... '
        BlackStack::Pampa.dispatch
        l.done
        
    # note: this catches the CTRL+C signal.
    # note: this catches the `kill` command, ONLY if it has not the `-9` option.
    rescue SignalException, SystemExit, Interrupt => e                    
        l.logf 'Bye!'
        raise e
    rescue => e
        l.logf 'Error: '+e.to_console                
    end
    
    # release resource
    l.logs 'Releasing resources... '
    GC.start
    DB.disconnect
    l.done
    
    # get the end loop time
    l.logs 'Ending loop... '
    finish = Time.now()
    l.done
            
    # get different in seconds between start and finish
    # if diff > 30 seconds
    l.logs 'Calculating loop duration... '
    diff = finish - start
    l.logf 'done ('+diff.to_s+')'

    if diff < PARSER.value('delay')
        # sleep for 30 seconds
        n = PARSER.value('delay')-diff
                
        l.logs 'Sleeping for '+n.to_label+' seconds... '
        sleep n
        l.done
    else
        l.log 'No sleeping. The loop took '+diff.to_label+' seconds.'
    end

end