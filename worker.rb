# require the gem simple_cloud_logging for parsing command line parameters.
require 'simple_command_line_parser'
# require the gem simple_cloud_logging for writing logfiles.
require 'simple_cloud_logging'
# require the gem sequel for connecting to the database and handle ORM classes.
require 'sequel'

# parse command line parameters
PARSER = BlackStack::SimpleCommandLineParser.new(
    :description => 'This script starts an infinite loop. Each loop will look for a task to perform. Must be a delay between each loop.',
    :configuration => [{
        :name=>'delay',
        :mandatory=>false,
        :default=>30, 
        :description=>'Minimum delay between loops. A minimum of 10 seconds is recommended, in order to don\'t hard the database server. Default is 30 seconds.', 
        :type=>BlackStack::SimpleCommandLineParser::INT,
    }, {
        :name=>'debug', 
        :mandatory=>false,
        :default=>false, 
        :description=>'Activate this flag if you want to require the `pampa.rb` file from the same Pampa project folder, insetad to require the gem as usual.', 
        :type=>BlackStack::SimpleCommandLineParser::BOOL,
    }, {
        :name=>'pampa', 
        :mandatory=>false,
        :default=>'./lib/pampa.rb', 
        :description=>'Ruby file to require where `debug` is activated.', 
        :type=>BlackStack::SimpleCommandLineParser::STRING,
    }, {
        :name=>'config', 
        :mandatory=>false,
        :default=>'./config.rb', 
        :description=>'Ruby file where is defined the connection-string and jobs.', 
        :type=>BlackStack::SimpleCommandLineParser::STRING,
    }, {
        :name=>'id', 
        :mandatory=>true, 
        :description=>'Write here a unique identifier for the worker.', 
        :type=>BlackStack::SimpleCommandLineParser::STRING,
    }]
)

# creating logfile
l = BlackStack::LocalLogger.new('worker.'+PARSER.value('id').to_s+'.log')
  
begin
    # log the paramers
    l.log 'STARTING WORKER'

    # show the parameters
    # TODO: replace this hardocded array for method `PARSER.params`.
    # reference: https://github.com/leandrosardi/simple_command_line_parser/issues/7
    #['id','delay','debug','pampa','config'].each { |param| l.log param + ': ' + PARSER.value(param).to_s }

    # require the pampa library
    l.logs 'Requiring pampa (debug='+(PARSER.value('debug') ? 'true' : 'false')+', pampa='+PARSER.value('pampa')+')... '
    require 'pampa' if !PARSER.value('debug')
    require PARSER.value('pampa') if PARSER.value('debug')
    l.done

    # requiore the config.rb file where the jobs are defined.
    l.logs 'Requiring config (config='+PARSER.value('config')+')... '
    require PARSER.value('config')
    l.done

    # getting the worker object
    worker = BlackStack::Pampa.workers.select { |w| w.id == PARSER.value('id') }.first
    raise 'Worker '+PARSER.value('id')+' not found.' if worker.nil?

    # start the loop
    while true
        # get the start loop time
        l.logs 'Starting loop... '
        start = Time.now()
        l.done        

        BlackStack::Pampa.jobs.each { |job|
            l.logs 'Processing job '+job.name+'... '
            tasks = job.occupied_slots(worker)
            l.logf tasks.size.to_s+' tasks in queue.'

            tasks.each { |task|
                l.logs 'Flag task '+job.name+'.'+task[job.field_primary_key.to_sym].to_s+' started... '
                job.start(task)
                l.done

                begin
                    l.logs 'Processing task '+task[job.field_primary_key.to_sym].to_s+'... '
                    job.processing_function.call(task, l, job, worker)
                    l.done

                # note: this catches the CTRL+C signal.
                # note: this catches the `kill` command, ONLY if it has not the `-9` option.
                rescue SignalException, SystemExit, Interrupt => e
                    l.logs 'Flag task '+job.name+'.'+task[job.field_primary_key.to_sym].to_s+' interrumpted... '
                    job.finish(task, e)
                    l.done
                    
                    log.logf 'Bye!'

                    raise e

                rescue => e
                    l.logs 'Flag task '+job.name+'.'+task[job.field_primary_key.to_sym].to_s+' failed... '
                    job.finish(task, e)
                    l.done

                    l.logf 'Error: '+e.to_console
                
                rescue 
                    l.logs 'Flag task '+job.name+'.'+task[job.field_primary_key.to_sym].to_s+' failed with unknown error... '
                    job.finish(task, e)
                    l.done

                    l.logf 'Unknown Error.'
                
                end
        
                l.logs 'Flag task '+job.name+'.'+task[job.field_primary_key.to_sym].to_s+' finished... '
                job.finish(task)
                l.done
            }
        }

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
    end # while true
rescue SignalException, SystemExit, Interrupt
    # note: this catches the CTRL+C signal.
    # note: this catches the `kill` command, ONLY if it has not the `-9` option.
    l.logf 'Process Interrumpted.'
rescue => e
    l.logf 'Fatal Error: '+e.to_console
rescue 
    l.logf 'Unknown Fatal Error.'
end