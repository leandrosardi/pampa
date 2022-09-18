require 'sequel'
require 'blackstack-core'
require 'blackstack-nodes'
require 'simple_command_line_parser'
require 'simple_cloud_logging'

module BlackStack
    module Pampa
        # arrays of workers, nodes, and jobs.
        @@workers = []
        @@nodes = []
        @@jobs = []
        # logger configuration
        @@log_filename = nil
        @@logger = BlackStack::DummyLogger.new(nil)
        # Connection string to the database. Example: mysql2://user:password@localhost:3306/database
        @@connection_string = nil
        
        # define a filename for the log file.
        def self.set_log_filename(s)
            @@log_filename = s
            @@logger = BlackStack::LocalLogger.new(s)
        end

        # return the logger.
        def self.logger()
            @@logger
        end

        # return the log filename.
        def self.log_filename()
            @@log_filename
        end

        # define a connection string to the database.
        def self.set_connection_string(s)
            @@connection_string = s
        end

        # return connection string to the database. Example: mysql2://user:password@localhost:3306/database
        def self.connection_string()
            @@connection_string
        end

        # add a node to the cluster.
        def self.add_node(h)
            @@nodes << BlackStack::Pampa::Node.new(h)
        end # def self.add_node(h)

        # add an array of nodes to the cluster.
        def self.add_nodes(a)
            # validate: the parameter a is an array
            raise "The parameter a is not an array" unless a.is_a?(Array)
            # iterate over the array
            a.each do |h|
                # create the node
                self.add_node(h)
            end
        end # def self.add_nodes(a)

        # add a job to the cluster.
        def self.add_job(h)
            @@jobs << BlackStack::Pampa::Job.new(h)
        end # def self.add_job(h)

        # add an array of jobs to the cluster.
        def self.add_jobs(a)
            # validate: the parameter a is an array
            raise "The parameter a is not an array" unless a.is_a?(Array)
            # iterate over the array
            a.each do |h|
                # create the job
                self.add_job(h)
            end
        end # def self.add_jobs(a)
=begin
        # return a hash descriptor of the whole configuration of the cluster.
        def self.to_hash()
            ret = {
                :log_filename => self.log_filename,
                :connection_string => self.connection_string,
            }
            #ret[:workers] = []
            #@@workers.each do |w|
            #    ret[:workers] << w.to_hash
            #end
            ret[:nodes] = []
            @@nodes.each do |n|
                ret[:nodes] << n.to_hash
            end
            ret[:jobs] = []
            @@jobs.each do |j|
                ret[:jobs] << j.to_hash
            end
            ret
        end # def self.to_hash()

        # setup from a whole hash descriptor
        def self.initialize(h)
            # TODO
        end
=end
        # connect the nodes via ssh.
        # rename any existing folder ~/pampa to ~/pampa.<current timestamp>.
        # create a new folder ~/pampa.
        # build the file ~/pampa/config.rb in the remote node.
        # copy the file ~/pampa/worker.rb to the remote node.
        # run the number of workers specified in the configuration of the Pampa module.
        # return an array with the IDs of the workers.
        #
        # Parameters:
        # - config: relative path of the configuration file. Example: '../config.rb'
        # - worker: relative path of the worker.rb file. Example: '../worker.rb'
        # 
        def self.deploy(config_filename='./config.rb', worker_filename='./worker.rb')
            # validate: the connection string is not nil
            raise "The connection string is nil" if @@connection_string.nil?
            # validate: the connection string is not empty
            raise "The connection string is empty" if @@connection_string.empty?
            # validate: the connection string is not blank
            raise "The connection string is blank" if @@connection_string.strip.empty?
            # getting logger
            l = self.logger()
            # iterate the nodes
            @@nodes.each { |node|
                l.logs("node:#{node.name()}... ")
                    # connect the node
                    l.logs("Connecting... ")
                    node.connect()
                    l.done
                    # rename any existing folder ~/code/pampa to ~/code/pampa.<current timestamp>.
                    l.logs("Renaming old folder... ")
                    node.exec('mv ~/pampa ~/pampa.'+Time.now().to_i.to_s, false)
                    l.done
                    # create a new folder ~/code. - ignore if it already exists.
                    l.logs("Creating new folder... ")
                    node.exec('mkdir ~/pampa', false)
                    l.done
                    # build the file ~/pampa/config.rb in the remote node. - Be sure the BlackStack::Pampa.to_hash.to_s don't have single-quotes (') in the string.
                    l.logs("Building config file... ")
                    s = "echo \"#{File.read(config_filename)}\" > ~/pampa/config.rb"                    
                    node.exec(s, false)
                    l.done
                    # copy the file ~/pampa/worker.rb to the remote node. - Be sure the script don't have single-quotes (') in the string.
                    l.logs("Copying worker file... ")
                    s = "echo \"#{File.read(worker_filename)}\" > ~/pampa/worker.rb"
                    node.exec(s, false)
                    l.done
                    # run the number of workers specified in the configuration of the Pampa module.
                    node.workers.each { |worker|
                        # run the worker
                        l.logs "Running worker #{worker.id}... "
                        s = "
                          source /home/#{node.ssh_username}/.rvm/scripts/rvm; 
                          rvm install 3.1.2; 
                          rvm --default use 3.1.2;
                          cd /home/#{node.ssh_username}/pampa; 
                          export RUBYLIB=/home/#{node.ssh_username}/pampa;
                          nano ruby worker.rb id=#{worker.id} config=~/pampa/config.rb debug=yes pampa=~/code/pampa/lib/pampa.rb 2>&1 1>/dev/null &
                        "
                        puts node.exec(s, false)
                        l.done
                    }
                    # disconnect the node
                    l.logs("Disconnecting... ")
                    node.disconnect()
                    l.done
                l.done
            } # @@nodes.each do |node|            
        end

        # stub worker class
        class Worker
            # name to identify uniquely the worker
            attr_accessor :id
            # return an array with the errors found in the description of the job
            def self.descriptor_errors(h)
                errors = []
                # TODO: Code Me!
                errors.uniq
            end
            # setup dispatcher configuration here
            def initialize(h)
              errors = BlackStack::Pampa::Worker.descriptor_errors(h)
              raise "The worker descriptor is not valid: #{errors.uniq.join(".\n")}" if errors.length > 0        
              self.id = h[:id]
            end
            # return a hash descriptor of the worker
            def to_hash()
                {
                    :id => self.id,
                }
            end
        end

        # stub node class
        # stub node class is already defined in the blackstack-nodes gem: https://github.com/leandrosardi/blackstack-nodes
        # we inherit from it to add some extra methods and attributes
        class Node
            # stub node class is already defined in the blackstack-nodes gem: https://github.com/leandrosardi/blackstack-nodes
            # we inherit from it to add some extra methods and attributes
            include BlackStack::Infrastructure::NodeModule
            # array of workers belonging to this node
            attr_accessor :max_workers
            attr_accessor :workers
            # add validations to the node descriptor
            def self.descriptor_errors(h)
                errors = BlackStack::Infrastructure::NodeModule.descriptor_errors(h)
                # validate: the key :max_workers exists and is an integer
                errors << "The key :max_workers is missing" if h[:max_workers].nil?
                errors << "The key :max_workers must be an integer" unless h[:max_workers].is_a?(Integer)
                # return list of errors
                errors.uniq
              end
              # initialize the node
              def initialize(h, i_logger=nil)
                errors = BlackStack::Pampa::Node.descriptor_errors(h)
                raise "The node descriptor is not valid: #{errors.uniq.join(".\n")}" if errors.length > 0
                super(h, i_logger)
                self.max_workers = h[:max_workers]
                self.workers = []
                self.max_workers.times do |i|
                    self.workers << BlackStack::Pampa::Worker.new({:id => i, :node => self.to_hash})
                end
            end # def self.create(h)
            # returh a hash descriptor of the node
            def to_hash()
                ret = super()
                ret[:max_workers] = self.max_workers
                ret[:workers] = []
                self.workers.each do |worker|
                    ret[:workers] << worker.to_hash
                end
                ret
            end
        end # class Node

        # stub job class
        class Job
            attr_accessor :name
            # database information
            # :field_times, :field_start_time and :field_end_time maybe nil
            attr_accessor :table
            attr_accessor :field_primary_key
            attr_accessor :field_id
            attr_accessor :field_time 
            attr_accessor :field_times
            attr_accessor :field_start_time
            attr_accessor :field_end_time
            # max number of records assigned to a worker that have not started (:start_time field is nil)
            attr_accessor :queue_size 
            # max number of minutes that a job should take to process. if :end_time keep nil x minutes 
            # after :start_time, that's considered as the job has failed or interrumped
            attr_accessor :max_job_duration_minutes  
            # max number of times that a record can start to process & fail (:start_time field is not nil, 
            # but :end_time field is still nil after :max_job_duration_minutes)
            attr_accessor :max_try_times
            # additional function to returns an array of objects pending to be processed by a worker.
            # it should returns an array
            # keep it nil if you want to run the default function
            attr_accessor :occupied_function
            # additional function to decide if the worker can dispatch or not
            # example: use this function when you want to decide based on the remaining credits of the client
            # it should returns true or false
            # keep it nil if you want it returns always true
            attr_accessor :allowing_function
            # additional function to choose the records to launch
            # it should returns an array of IDs
            # keep this parameter nil if you want to use the default algorithm
            attr_accessor :selecting_function
            # additional function to choose the records to retry
            # keep this parameter nil if you want to use the default algorithm
            attr_accessor :relaunching_function
            # additional function to perform the update on a record to retry
            # keep this parameter nil if you want to use the default algorithm
            attr_accessor :relauncher_function
            # additional function to perform the update on a record to flag the starting of the job
            # by default this function will set the :field_start_time field with the current datetime, and it will increase the :field_times counter 
            # keep this parameter nil if you want to use the default algorithm
            attr_accessor :starter_function
            # additional function to perform the update on a record to flag the finishing of the job
            # by default this function will set the :field_end_time field with the current datetime 
            # keep this parameter nil if you want to use the default algorithm
            attr_accessor :finisher_function
            # Function to execute for each task.
            attr_accessor :processing_function
            
            # return a hash descriptor of the job
            def to_hash()
                {
                    :name => self.name,
                    :table => self.table,
                    :field_primary_key => self.field_primary_key,
                    :field_id => self.field_id,
                    :field_time => self.field_time,
                    :field_times => self.field_times,
                    :field_start_time => self.field_start_time,
                    :field_end_time => self.field_end_time,
                    :queue_size => self.queue_size,
                    :max_job_duration_minutes => self.max_job_duration_minutes,
                    :max_try_times => self.max_try_times,
                    :occupied_function => self.occupied_function.to_s,
                    :allowing_function => self.allowing_function.to_s,
                    :selecting_function => self.selecting_function.to_s,
                    :relaunching_function => self.relaunching_function.to_s,
                    :relauncher_function => self.relauncher_function.to_s,
                    :starter_function => self.starter_function.to_s,
                    :finisher_function => self.finisher_function.to_s,
                    :processing_function => self.processing_function.to_s
                }
            end

            # return an array with the errors found in the description of the job
            def self.descriptor_errors(h)
                errors = []
                # TODO: Code Me!
                errors.uniq
            end

            # setup dispatcher configuration here
            def initialize(h)
              errors = BlackStack::Pampa::Job.descriptor_errors(h)
              raise "The job descriptor is not valid: #{errors.uniq.join(".\n")}" if errors.length > 0        
              self.name = h[:name]
              self.table = h[:table]
              self.field_primary_key = h[:field_primary_key]
              self.field_id = h[:field_id]
              self.field_time = h[:field_time]
              self.field_times = h[:field_times]
              self.field_start_time = h[:field_start_time]
              self.field_end_time = h[:field_end_time]
              self.queue_size = h[:queue_size]
              self.max_job_duration_minutes = h[:max_job_duration_minutes]  
              self.max_try_times = h[:max_try_times]
              self.occupied_function = h[:occupied_function]
              self.allowing_function = h[:allowing_function]
              self.selecting_function = h[:selecting_function]
              self.relaunching_function = h[:relaunching_function]
              self.relauncher_function = h[:relauncher_function]
              self.processing_function = h[:processing_function]
            end
            
            # returns an array of objects pending to be processed by the worker.
            # it will select the records with :reservation_id == worker.id, and :start_time == nil
            def occupied_slots(worker)
              if self.occupied_function.nil?
                return self.table.where(self.field_id.to_sym => worker.id, self.field_start_time.to_sym => nil).all if !self.field_start_time.nil?
                return self.table.where(self.field_id.to_sym => worker.id).all if self.field_start_time.nil?
              else
                # TODO: validar que retorna un entero
                return self.occupied_function.call(worker, self)
              end
            end
        
            # returns the number of free slots in the procesing queue of this worker
            def available_slots(worker)
              occupied = self.occupied_slots(worker).size
              allowed = self.queue_size
              if occupied > allowed
                return 0
              else
                return allowed - occupied
              end
            end
        
            # decide if the worker can dispatch or not
            # example: use this function when you want to decide based on the remaining credits of the client
            # returns always true
            def allowing(worker)
              if self.allowing_function.nil?
                return true
              else
                # TODO: validar que retorna true o false
                return self.allowing_function.call(worker, self)
              end
            end
        
            # choose the records to dispatch
            # returns an array of IDs
            def selecting_dataset(worker, n)
              ds = self.table.select(self.field_primary_key.to_sym).where(self.field_id.to_sym => nil) 
              ds = ds.filter(self.field_end_time.to_sym => nil) if !self.field_end_time.nil?  
              ds = ds.filter("#{self.field_times.to_s} IS NULL OR #{self.field_times.to_s} < #{self.max_try_times.to_s}") if !self.field_times.nil? 
              ds.limit(n)
            end # selecting_dataset
        
            def selecting(worker, n)
              if self.selecting_function.nil?
                return self.selecting_dataset(worker, n).map { |o| o[self.field_primary_key.to_sym] }
              else
                # TODO: validar que retorna un array de strings
                return self.selecting_function.call(worker, self, n)
              end
            end
        
            # choose the records to retry
            # returns an array of IDs
            def relaunching_dataset(worker, n)
              ds = self.table.select(self.field_primary_key.to_sym).where("#{self.field_time.to_s} < DATEADD(mi, -#{self.max_job_duration_minutes.to_i}, GETDATE())")
              ds = ds.filter("#{self.field_end_time.to_s} IS NULL") if !self.field_end_time.nil?  
              #ds = ds.filter("( #{self.field_times.to_s} IS NULL OR #{self.field_times.to_s} < #{self.max_try_times.to_s} ) ") if !self.field_times.nil?
              ds = ds.limit(n)
              ds
            end
        
            def relaunching(worker, n)
              if self.relaunching_function.nil?
                return self.relaunching_dataset(worker, n).map { |o| o[self.field_primary_key.to_sym] }
              else
                # TODO: validar que retorna un array de strings
                return self.relaunching_function.call(worker, self, n)
              end
            end
            
            def relaunch(o)
              o[self.field_id.to_sym] = nil
              o[self.field_time.to_sym] = nil
              o[self.field_start_time.to_sym] = nil if !self.field_start_time.nil?
              o[self.field_end_time.to_sym] = nil if !self.field_end_time.nil?
              o.save      
            end
        
            def start(o)
              if self.starter_function.nil?
                o[self.field_start_time.to_sym] = now() if !self.field_start_time.nil?
                o[self.field_times.to_sym] = o[self.field_times.to_sym].to_i + 1
                o.save
              else
                self.starter_function.call(o, self)
              end
            end
        
            def finish(o)
              if self.finisher_function.nil?
                o[self.field_end_time.to_sym] = now() if !self.field_end_time.nil?
                o.save
              else
                self.finisher_function.call(o, self)
              end
            end
            
            # relaunch records
            def run_relaunch(worker)
              # relaunch failed records
              self.relaunching(worker, self.queue_size).each { |id|
                o = self.table.where(self.field_primary_key.to_sym => id).first
                if self.relauncher_function.nil?
                  self.relaunch(o)
                else
                  self.relauncher_function.call(o, self)
                end
                # release resources
                DB.disconnect
                GC.start
              }
            end # def run_relaunch
            
            # dispatch records
            # returns the # of records dispatched
            def run_dispatch(worker)
              # get # of available slots
              n = self.available_slots(worker)
              
              # dispatching n pending records
              i = 0
              if n>0
                self.selecting(worker, n).each { |id|
                  # count the # of dispatched
                  i += 1
                  # dispatch records
                  o = self.table.where(self.field_primary_key.to_sym => id).first
                  o[self.field_id.to_sym] = worker.id
                  o[self.field_time.to_sym] = now()
                  o[self.field_start_time.to_sym] = nil if !self.field_start_time.nil?
                  o[self.field_end_time.to_sym] = nil if !self.field_end_time.nil?
                  o.save
                  # release resources
                  DB.disconnect
                  GC.start        
                }
              end
              
              #      
              return i
            end
        end # class Job
    end # module Pampa
end # module BlackStack