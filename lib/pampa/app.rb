# MySaaS - Pampa Dashboard
# Copyright (C) 2022 ExpandedVenture, LLC.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# You may not use this file except in compliance with the License.
#
# Authors: Leandro Daniel Sardi (https://github.com/leandrosardi)
#

require 'pampa'
require "rubygems"

# 
PARSER = BlackStack::SimpleCommandLineParser.new(
  :description => 'This command will launch a Sinatra-based Pampa dashboard.', 
  :configuration => [{
    :name=>'port', 
    :mandatory=>false, 
    :description=>'Listening port. Default: 3000.', 
    :type=>BlackStack::SimpleCommandLineParser::INT,
    :default => 3000,
  }, {
    :name=>'config', 
    :mandatory=>false, 
    :description=>'Configuration file. Default: "config.rb".', 
    :type=>BlackStack::SimpleCommandLineParser::STRING,
    :default => 'config.rb',
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
    :description=>'If write log in the file ./app.log or not. Default: "yes"', 
    :type=>BlackStack::SimpleCommandLineParser::BOOL,
  }]
)

# create logger
l = PARSER.value('log') ? BlackStack::LocalLogger.new('app.log') : BlackStack::BaseLogger.new(nil)

#
# load config file
l.logs "Loading #{PARSER.value('config').to_s.blue}... "
require PARSER.value('config')
l.logf 'done'.green

l.logs 'Connecting to database... '
if PARSER.value('db') == 'postgres'
    DB = BlackStack::PostgreSQL::connect
elsif PARSER.value('db') == 'crdb'
    DB = BlackStack::CockroachDB::connect
else
    raise 'Unknown database driver.'
end
l.logf 'done'.green

# 
spec = Gem.loaded_specs['pampa']
puts '
_______  _______  __   __  _______  _______ 
|       ||   _   ||  |_|  ||       ||   _   |
|    _  ||  |_|  ||       ||    _  ||  |_|  |
|   |_| ||       ||       ||   |_| ||       |
|    ___||       ||       ||    ___||       |
|   |    |   _   || ||_|| ||   |    |   _   |
|___|    |__| |__||_|   |_||___|    |__| |__|

Version: '+spec.version.to_s.green+'.
Authors: '+spec.authors.join(', ').green+'.
Documentation: '+spec.homepage.blue+'

Sandbox: '+ (BlackStack.sandbox? ? 'yes'.green : 'no'.yellow) +'

'

PORT = PARSER.value("port")

configure { set :server, :puma }
set :bind, '0.0.0.0'
set :port, PORT
enable :sessions
enable :static

configure do
  enable :cross_origin
end  

before do
  headers 'Access-Control-Allow-Origin' => '*', 
          'Access-Control-Allow-Methods' => ['OPTIONS', 'GET', 'POST']  
end

set :protection, false

# Setting the root of views and public folders in the `~/code` folder in order to have access to extensions.
# reference: https://stackoverflow.com/questions/69028408/change-sinatra-views-directory-location
set :root,  '.'
set :views, '.'

# page not found redirection
not_found do
  redirect '/404'
end

# unhandled exception redirectiopn
error do
  max_lenght = 8000
  s = "message=#{CGI.escape(env['sinatra.error'].to_s)}&"
  s += "backtrace_size=#{CGI.escape(env['sinatra.error'].backtrace.size.to_s)}&"
  i = 0
  env['sinatra.error'].backtrace.each { |a| 
    a = "backtrace[#{i.to_s}]=#{CGI.escape(a.to_s)}&"
    and_more = "backtrace[#{i.to_s}]=..." 
    if (s+a).size > max_lenght - and_more.size
      s += and_more
      break
    else
      s += a
    end
    i += 1 
  }
  redirect "/500?#{s}"
end

# condition: api_key parameter is required too for the access points
set(:api_key) do |*roles|
  condition do
    @return_message = {}
    
    @return_message[:status] = 'success'

    # validate: the pages using the :api_key condition must work as post only.
    if request.request_method != 'POST'
      @return_message[:status] = 'Pages with an `api_key` parameter are only available for POST requests.'
      @return_message[:value] = ""
      halt @return_message.to_json
    end

    @body = JSON.parse(request.body.read)

    if !@body.has_key?('api_key')
      # libero recursos
      DB.disconnect 
      GC.start
      @return_message[:status] = "api_key is required on #{@body.to_s}"
      @return_message[:value] = ""
      halt @return_message.to_json
    end

    if !@body['api_key'].guid?
      # libero recursos
      DB.disconnect 
      GC.start
  
      @return_message[:status] = "Invalid api_key (#{@body['api_key']}))"
      @return_message[:value] = ""
      halt @return_message.to_json      
    end
    
    validation_api_key = @body['api_key'].to_guid.downcase

    if validation_api_key != API_KEY
      # libero recursos
      DB.disconnect 
      GC.start
      #     
      @return_message[:status] = 'Wrong api_key'
      @return_message[:value] = ""
      halt @return_message.to_json        
    end
  end
end

get '/404', :agent => /(.*)/ do
  erb :'views/404', :layout => :'/views/layouts/public'
end

get '/500', :agent => /(.*)/ do
  erb :'views/500', :layout => :'/views/layouts/public'
end

# dashboard
get '/', :agent => /(.*)/ do
  redirect '/dashboard'
end
get '/dashboard', :agent => /(.*)/ do
  erb :'views/dashboard', :layout => :'/views/layouts/public'
end
