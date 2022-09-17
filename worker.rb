# require the gem simple_cloud_logging for parsing command line parameters.
require 'simple_command_line_parser'
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
        :default=>'./config.rb', 
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
        :description=>'Write here a unique identifier of the worker in this node.', 
        :type=>BlackStack::SimpleCommandLineParser::STRING,
    }]
)

# require the pampa library
require 'pampa' if !PARSER.value('debug')
require PARSER.value('pampa') if PARSER.value('debug')

# requiore the config.rb file where the jobs are defined.
require_relative PARSER.value('config')

# connect the database
s = BlackStack::Pampa.connection_string
DB = Sequel.connect(s)

# start the loop
while true
    # get the start loop time
    start = Time.now()
    
    # TODO: get the next task to process
    # TODO: process the tasks

    # get the end loop time
    finish = Time.now()
    
    # get different in seconds between start and finish
    diff = finish - start
    
    # if diff > 30 seconds
    if diff > PARSER.value('delay')
        # sleep for 30 seconds
        sleep diff-PARSER.value('delay')
    end
end