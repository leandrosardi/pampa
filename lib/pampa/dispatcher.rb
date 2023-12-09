# Pampa Dispatcher
# Copyright (C) 2022 ExpandedVenture, LLC.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# You may not use this file except in compliance with the License.
#
# Authors: Leandro Daniel Sardi (https://github.com/leandrosardi)
#

require 'pampa'

# parse command line parameters
PARSER = BlackStack::SimpleCommandLineParser.new(
    :description => 'This script starts an infinite loop. Each loop will look for a task to perform. Must be a delay between each loop.',
    :configuration => [{
        :name=>'delay',
        :mandatory=>false,
        :default=>10, # 5 minutes 
        :description=>'Minimum delay between loops. A minimum of 10 seconds is recommended, in order to don\'t hard the database server. Default is 30 seconds.', 
        :type=>BlackStack::SimpleCommandLineParser::INT,
    }, {
        :name=>'config',
        :mandatory=>false,
        :default=>'config.rb', 
        :description=>'Configuration file. Default: config.', 
        :type=>BlackStack::SimpleCommandLineParser::STRING,
    }, {
        :name=>'db',
        :mandatory=>false,
        :default=>'postgres', 
        :description=>'Database driver. Supported values: postgres, crdb. Default: postgres.', 
        :type=>BlackStack::SimpleCommandLineParser::STRING,
    }, {
        :name=>'log',
        :mandatory=>false,
        :default=>true, 
        :description=>'If write log in the file ./dispatcher.log or not. Default: "yes"', 
        :type=>BlackStack::SimpleCommandLineParser::BOOL,
    }]
)

# create logger
l = PARSER.value('log') ? BlackStack::LocalLogger.new('dispatcher.log') : BlackStack::BaseLogger.new(nil)

# assign logger to pampa
BlackStack::Pampa.set_logger(l)

# load config file
l.logs "Loading #{PARSER.value('config').to_s.blue}... "
require PARSER.value('config')
l.logf 'done'.green

l.logs 'Connecting to database... '
if PARSER.value('db') == 'postgres'
    DB = BlackStack::PostgreSQL::connect
elsif PARSER.value('db') == 'crdb'
    DB = BlackStack::CRDB::connect
else
    raise 'Unknown database driver.'
end
l.logf 'done'.green

# call dispatcher code snippet
l.logs 'Calling dispatcher code snippet... '
f = BlackStack::Pampa.dispatcher_function
if f 
    f.call(l)
    l.logf 'done'.green
else
    l.logf 'no dispatcher code snippet found'.yellow
end 

# loop
begin    
    while true
        # get the start loop time
        l.logs 'Starting loop... '
        start = Time.now()
        l.logf 'done'.green        

        begin
            # assign workers to each job
            l.logs 'Stretching clusters... '
            BlackStack::Pampa.stretch
            l.logf 'done'.green

            # relaunch expired tasks
            l.logs 'Relaunching expired tasks... '
            BlackStack::Pampa.relaunch
            l.logf 'done'.green

            # dispatch tasks to each worker
            l.logs 'Dispatching tasks to workers... '
            BlackStack::Pampa.dispatch
            l.logf 'done'.green
            
        # note: this catches the CTRL+C signal.
        # note: this catches the `kill` command, ONLY if it has not the `-9` option.
        rescue SignalException, SystemExit, Interrupt => e                    
            l.logf 'Bye!'.yellow
            raise e
        rescue => e
            l.logf "Error: #{e.to_console}".red                
        end
        
        # release resource
        l.logs 'Releasing resources... '
        GC.start
        DB.disconnect
        l.logf 'done'.green
        
        # get the end loop time
        l.logs 'Ending loop... '
        finish = Time.now()
        l.logf 'done'.green
                
        # get different in seconds between start and finish
        # if diff > 30 seconds
        l.logs 'Calculating loop duration... '
        diff = finish - start
        l.logf 'done'.green + " (#{diff.to_s.blue})"

        if diff < PARSER.value('delay')
            # sleep for 30 seconds
            n = PARSER.value('delay')-diff
                    
            l.logs 'Sleeping for '+n.to_label+' seconds... '
            sleep n
            l.logf 'done'.green
        else
            l.log 'No sleeping. The loop took '+diff.to_label+' seconds.'
        end
    end # while true
rescue SignalException, SystemExit, Interrupt
    # note: this catches the CTRL+C signal.
    # note: this catches the `kill` command, ONLY if it has not the `-9` option.
    l.logf 'Process Interrumpted.'.yellow
    l.log 'Bye!'.yellow
rescue => e
    l.logf "Fatal Error: #{e.to_console}".red
rescue 
    l.logf 'Unknown Fatal Error.'.red
end # begin