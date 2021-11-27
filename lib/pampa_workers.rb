require 'simple_host_monitoring'
require 'socket'
require 'time'
require 'uri'
require 'net/http'
require 'json'
require 'openssl'
require 'tiny_tds'
require 'sequel'

require_relative './baseworker'
require_relative './basedivision'

require_relative './remoteworker'
require_relative './remotedivision'

require_relative './myprocess'
require_relative './mychildprocess'
require_relative './mylocalprocess'
require_relative './myparentprocess'
require_relative './myremoteprocess'
require_relative './mycrawlprocess'
require_relative './remoteworker'
require_relative './remotedivision'

module BlackStack
  
  module Pampa

    SLEEP_SECONDS = 10

    # 
    @@division_name = nil
    @@timeout = 7

    def self.division_name() 
      @@division_name
    end

    #
    def self.set_division_name(s) 
      @@division_name = s
    end

    def self.timeout() 
      @@timeout
    end

    #
    def self.set_timeout(n) 
      @@timeout = n
    end

    # Api-key of the client who will be the owner of a process.
    @@api_key = nil
    
    def self.api_key()
      @@api_key 
    end
    
    # Protocol, HTTP or HTTPS, of the BlackStack server where this process will be registered.
    @@api_protocol = nil
    
    #
    def self.api_protocol
      @@api_protocol
    end 

    # Domain of the BlackStack server where this process will be registered.
    @@api_domain = nil
    
    #
    def self.api_domain
      @@api_domain
    end

    # Port of the BlackStack server where this process will be registered.
    @@api_port = nil
    
    #
    def self.api_port
      @@api_port
    end
    
    # get the full URL of the worker api server
    def self.api_url()
      "#{BlackStack::Pampa::api_protocol}://#{BlackStack::Pampa::api_domain}:#{BlackStack::Pampa::api_port}"
    end
    
    # 
    def self.set_api_key(s)
      @@api_key = s
    end

    # 
    def self.set_api_url(h)
      @@api_key = h[:api_key]
      @@api_protocol = h[:api_protocol]
      @@api_domain = h[:api_domain]
      @@api_port = h[:api_port]
    end

    # path where you will store the data of each client
    @@storage_folder = nil
    @@storage_sub_folders = []

    #
    def self.storage_folder()
      @@storage_folder
    end
    def self.storage_sub_folders()
      @@storage_sub_folders
    end

    #
    def self.set_storage_folder(path)
      @@storage_folder = path
    end
    def self.set_storage_sub_folders(a)
      @@storage_sub_folders = a
    end
    

    #
    # default timezome for any new user
    #
    #
    @@id_timezone_default = nil

    #
    def self.id_timezone_default()
      @@id_timezone_default
    end

    #
    def self.set_id_timezone_default(id)
      @@id_timezone_default = id
    end

    # Array of external IP addresses of the servers where farms are running.
    # If you have many servers running behind a NAT server, only add the IP 
    # of the external gateway here. This array is used to know if a worker 
    # is running inside your farm datacenter, or it is running in the computer 
    # of someone else.  
    @@farm_external_ip_addresses = []

    #
    def self.farm_external_ip_addresses()
      @@farm_external_ip_addresses
    end

    #
    def self.set_farm_external_ip_addresses(a)
      @@farm_external_ip_addresses = a
    end

    # 
    def self.get_guid
      res = BlackStack::Netting::call_post(
        "#{self.api_url}/api1.4/get_guid.json",
        {'api_key' => @@api_key}
      )
      parsed = JSON.parse(res.body)
      parsed['value']        
    end

    # Central database connection parameters
    @@db_url = nil
    @@db_port = nil
    @@db_name = nil
    @@db_user = nil
    @@db_password = nil
    
    #
    def self.db_url
      @@db_url
    end
    
    #
    def self.db_port
      @@db_port
    end
    
    #
    def self.db_name
      @@db_name
    end
    
    #
    def self.db_user
      @@db_user
    end
    
    #
    def self.db_password
      @@db_password
    end

    # Set connection params to the central database
    def self.set_db_params(h)
      @@db_url = h[:db_url]
      @@db_port = h[:db_port]
      @@db_name = h[:db_name]
      @@db_user = h[:db_user]
      @@db_password = h[:db_password]
    end

    # TODO: doc me!
    def self.connection_descriptor()           
      ret = nil
      
      # validar que el formato no sea nulo
      if (self.division_name.to_s.length == 0)
        raise "Division name expected."
      end
  
      if (self.division_name == "local") 
        ret = {
          :adapter => 'tinytds',
          :dataserver => BlackStack::Pampa::db_url, # IP or hostname
          :port => BlackStack::Pampa::db_port, # Required when using other that 1433 (default)
          :database => BlackStack::Pampa::db_name,
          :user => BlackStack::Pampa::db_user,
          :password => BlackStack::Pampa::db_password,
          :timeout => BlackStack::Pampa::timeout
          }      
      else
        url = "#{BlackStack::Pampa::api_url}/api1.2/division/get.json"
        res = BlackStack::Netting::call_post(url, {
          'api_key' => BlackStack::Pampa::api_key, 
          'dname' => "#{self.division_name}",
        })
        parsed = JSON.parse(res.body)
        
        if (parsed["status"] != BlackStack::Netting::SUCCESS)
          raise "Error getting connection string: #{parsed["status"]}"
        else
          wid = parsed["value"]
          
          ret = {
            :adapter => 'tinytds',
            :dataserver => parsed["db_url"], # IP or hostname
            :port => parsed["db_port"], # only required if port is different than 1433
            :database => parsed["db_name"],
            :user => parsed["db_user"],
            :password => parsed["db_password"],
            :timeout => BlackStack::Pampa::timeout
          }
        end
      end
  
      ret
    end # connectionDescriptor

    # 
    def self.db_connection()
      Sequel.connect(BlackStack::Pampa::connection_descriptor)
    end
    
    #
    def self.require_db_classes()
      # You have to load all the Sinatra classes after connect the database.
      require_relative '../lib/pampa-local.rb'
    end

  end # module Pampa
    
end # module BlackStack
