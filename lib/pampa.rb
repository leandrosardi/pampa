require 'blackstack-core'
require 'blackstack-db'
require 'blackstack-nodes'
require 'simple_command_line_parser'
require 'simple_cloud_logging'
require 'colorize'
require 'sinatra'

module BlackStack
    module Pampa
        # arrays of workers, nodes, and jobs.
        @@nodes = []
        @@jobs = []
        @@logger = BlackStack::DummyLogger.new(nil)

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

        # return the array of nodes.
        def self.nodes()
            @@nodes
        end

        # return the array of all workers, beloning all nodes.
        def self.workers()
          @@nodes.map { |node| node.workers }.flatten
        end

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

        # return the array of nodes.
        def self.jobs()
          @@jobs
        end

        # get and set logger
        def self.logger()
          @@logger
        end

        def self.set_logger(l)
          @@logger = l
        end

        # get attached and unassigned workers. 
        # assign and unassign workers to jobs.
        #
        # Parameters:
        # - config: relative path of the configuration file. Example: '../config.rb'
        # - worker: relative path of the worker.rb file. Example: '../worker.rb'
        # 
        def self.stretch()
          # getting logger
          l = self.logger()
          # get the job this worker is working with
          BlackStack::Pampa.jobs.each { |job|
            l.logs "job #{job.name}... "
              # get attached and unassigned workers 
              l.logs "Getting attached and unassigned workers... "
              workers = BlackStack::Pampa.workers.select { |w| w.attached && w.assigned_job.nil? }
              l.logf 'done'.green + " (#{workers.size.to_s.blue})"
              # get the workers that match the filter
              l.logs "Getting workers that match the filter... "
              workers = workers.select { |w| w.id =~ job.filter_worker_id }
              l.logf "done".green + " (#{workers.size.to_s.blue})"
              # if theere are workers
              if workers.size > 0
                l.logs("Gettting assigned workers... ") 
                assigned = BlackStack::Pampa.workers.select { |worker| worker.attached && worker.assigned_job.to_s == job.name.to_s }
                l.logf "done ".green + " (#{assigned.size.to_s.blue})"

                l.logs("Getting total pending (pending) tasks... ")
                pendings = job.pending
                l.logf "done".green + " (#{pendings.to_s.blue})"

                l.logs("0 pending tasks?.... ")
                if pendings.size == 0
                  l.logf "yes".green

                  l.logs("Unassigning all assigned workers... ")
                  assigned.each { |w|
                    l.logs("Unassigning worker... ")
                    w.assigned_job = nil
                    workers << w # add worker back to the list of unassigned
                    l.logf "done".green + " (#{w.id.to_s.blue})"
                  }
                  l.done
                else
                  l.logf "no".red

                  l.logs("Under :max_pending_tasks (#{job.max_pending_tasks}) and more than 1 assigned workers ?... ")
                  if pendings.size < job.max_pending_tasks && assigned.size > 1
                    l.logf "yes".green

                    while assigned.size > 1
                      l.logs("Unassigning worker... ")
                      w = assigned.pop # TODO: find a worker with no pending tasks
                      w.assigned_job = nil
                      workers << w # add worker back to the array of unassigned workers
                      l.logf "done".green + " (#{w.id.to_s.blue})"
                    end
                  else
                    l.logf "no".red

                    l.logs("Over :max_assigned_workers (#{job.max_assigned_workers.to_s.blue}) and more than 1 assigned workers?... ")
                    if assigned.size >= job.max_assigned_workers && assigned.size > 1
                      l.logf("yes".green)
                    else
                      l.logf("no".red)

                      i = assigned.size
                      while i < job.max_assigned_workers
                        i += 1
                        l.logs("Assigning worker... ")
                        w = workers.pop
                        if w.nil?
                          l.logf("no more workers".yellow)
                          break
                        else
                          w.assigned_job = job.name.to_sym
                          l.logf "done".green + " (#{w.id.to_s.blue})"
                        end
                      end # while i < job.max_assigned_workers
                    end # if assigned.size >= job.max_assigned_workers && assigned.size > 0
                  end # if pendings.size < job.max_pending_tasks && assigned.size > 1
                end # if pendings.size == 0
              end # if workers.size > 0
            l.done
          }
        end # def self.stretch()

        # iterate the jobs.
        # for each job, get all the tasks to relaunch.
        # for each task to relaunch, relaunch it.
        #
        # Parameters:
        # - config: relative path of the configuration file. Example: '../config.rb'
        # - worker: relative path of the worker.rb file. Example: '../worker.rb'
        # 
        def self.relaunch(n=10000)
          # getting logger
          l = self.logger()
          # iterate the workers
          BlackStack::Pampa.jobs.each { |job|
            l.logs("job:#{job.name}... ")
              l.logs("Gettting tasks to relaunch (max #{n})... ")
              tasks = job.relaunching(n)
              l.logf("done".green + " (#{tasks.size.to_s.blue})")

              tasks.each { |task| 
                l.logs("Relaunching task #{task[job.field_primary_key.to_sym]}... ")
                job.relaunch(task)
                l.done
              }

            l.done
          }
        end # def self.relaunch(n=10000)

        # iterate the workers.
        # for each worker, iterate the job.
        #
        # Parameters:
        # - config: relative path of the configuration file. Example: '../config.rb'
        # - worker: relative path of the worker.rb file. Example: '../worker.rb'
        # 
        def self.dispatch()
            # getting logger
            l = self.logger()
            # iterate the workers
            BlackStack::Pampa.workers.each { |worker|
                l.logs("worker:#{worker.id} (job:#{worker.assigned_job.to_s})... ")
                if !worker.attached
                  l.logf("detached".green)
                else
                  if worker.assigned_job.nil?
                    l.logf("unassigned".yellow)
                  else
                    # get the job this worker is assigned to
                    job = BlackStack::Pampa.jobs.select { |j| j.name.to_s == worker.assigned_job.to_s }.first
                    if job.nil?
                      l.logf("job #{job.name} not found".red)
                    else
                      l.logf("done".green + " (#{job.run_dispatch(worker).to_s.blue})")
                    end
                  end
                end
            } # @@nodes.each do |node|            
        end # def self.dispatch()

        # stub worker class
        class Worker
            # name to identify uniquely the worker
            attr_accessor :id, :assigned_job, :attached, :node
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
              self.assigned_job = nil
              self.attached = true
            end
            # return a hash descriptor of the worker
            def to_hash()
                {
                    :id => self.id,
                }
            end
            # attach worker to get dispatcher working with it
            def attach()
                self.attached = true
            end
            # detach worker to get dispatcher working with it
            def detach()
                self.attached = false
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
                    new_worker = BlackStack::Pampa::Worker.new({:id => "#{self.name}.#{(i+1).to_s}", :node => self.to_hash})
                    new_worker.node = self
                    self.workers << new_worker
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
            # kill all workers
            def kill_workers()
                self.workers.each do |worker|
                    self.kill_worker(worker.id)
                end
            end
            def kill_worker(worker_id)
                self.exec("kill -9 $(ps -ef | grep \"ruby worker.rb id=#{worker_id}\" | grep -v grep | awk '{print $2}')", false)
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
            attr_accessor :field_success
            attr_accessor :field_error_description
            # max number of records assigned to a worker that have not started (:start_time field is nil)
            attr_accessor :queue_size 
            # max number of minutes that a job should take to process. if :end_time keep nil x minutes 
            # after :start_time, that's considered as the job has failed or interrumped
            attr_accessor :max_job_duration_minutes  
            # max number of times that a record can start to process & fail (:start_time field is not nil, 
            # but :end_time field is still nil after :max_job_duration_minutes)
            attr_accessor :max_try_times

            # CUSTOM DISPATCHING FUNCTIONS
            # 
            # additional function to returns an array of tasks pending to be processed by a worker.
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

            # CUSTOM REPORTING FUNCTIONS
            # 
            # additional function to returns the number of total tasks.
            # it should returns an array
            # keep it nil if you want to run the default function
            attr_accessor :total_function
            attr_accessor :completed_function
            attr_accessor :pending_function
            attr_accessor :failed_function

            # ELASTIC WORKERS ASSIGNATION
            # 
            # stretch assignation/unassignation of workers
            attr_accessor :max_pending_tasks
            attr_accessor :max_assigned_workers

            # choose workers to assign tasks
            attr_accessor :filter_worker_id

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
                    :field_success => self.field_success,
                    :field_error_description => self.field_error_description,
                    :queue_size => self.queue_size,
                    :max_job_duration_minutes => self.max_job_duration_minutes,
                    :max_try_times => self.max_try_times,

                    # dispatching custom functions
                    :occupied_function => self.occupied_function.to_s,
                    :allowing_function => self.allowing_function.to_s,
                    :selecting_function => self.selecting_function.to_s,
                    :relaunching_function => self.relaunching_function.to_s,
                    :relauncher_function => self.relauncher_function.to_s,
                    :starter_function => self.starter_function.to_s,
                    :finisher_function => self.finisher_function.to_s,
                    :processing_function => self.processing_function.to_s,
                    :max_pending_tasks => self.max_pending_tasks,
                    :max_assigned_workers => self.max_assigned_workers,
                    :filter_worker_id => self.filter_worker_id,

                    # reporting custom functions
                    :total_function => self.total_function.to_s,
                    :completed_function => self.completed_function.to_s,
                    :pending_function => self.pending_function.to_s,
                    :failed_function => self.failed_function.to_s,
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
              self.field_success = h[:field_success]
              self.field_error_description = h[:field_error_description]
              self.queue_size = h[:queue_size]
              self.max_job_duration_minutes = h[:max_job_duration_minutes]  
              self.max_try_times = h[:max_try_times]

              # dispatching custom functions
              self.occupied_function = h[:occupied_function]
              self.allowing_function = h[:allowing_function]
              self.selecting_function = h[:selecting_function]
              self.relaunching_function = h[:relaunching_function]
              self.relauncher_function = h[:relauncher_function]
              self.processing_function = h[:processing_function]

              # reporting custom functions
              self.total_function = h[:total_function]
              self.completed_function = h[:completed_function]
              self.pending_function = h[:pending_function]
              self.failed_function = h[:failed_function]

              # elastic workers assignation
              self.max_pending_tasks = h[:max_pending_tasks]
              self.max_assigned_workers = h[:max_assigned_workers]
              self.filter_worker_id = h[:filter_worker_id]
            end
            
            # returns an array of tasks pending to be processed by the worker.
            # it will select the records with :reservation_id == worker.id, and :start_time == nil
            def occupied_slots(worker)
              if self.occupied_function.nil?
                return DB[self.table.to_sym].where(self.field_id.to_sym => worker.id, self.field_start_time.to_sym => nil).all if !self.field_start_time.nil?
                return DB[self.table.to_sym].where(self.field_id.to_sym => worker.id).all if self.field_start_time.nil?
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
        
            # returns an array of available tasks for dispatching.
            def selecting_dataset(n)
              ds = DB[self.table.to_sym].where(self.field_id.to_sym => nil) 
              ds = ds.filter(self.field_end_time.to_sym => nil) if !self.field_end_time.nil?  
              ds = ds.filter(Sequel.function(:coalesce, self.field_times.to_sym, 0)=>self.max_try_times.times.to_a) if !self.field_times.nil? 
              ds.limit(n).all
            end # selecting_dataset
        
            # returns an array of available tasks for dispatching.
            def selecting(n)
              if self.selecting_function.nil?
                return self.selecting_dataset(n)
              else
                # TODO: validar que retorna un array de strings
                return self.selecting_function.call(n, self)
              end
            end
        
            # returns an array of failed tasks for restarting.
            def relaunching_dataset(n)
              q = "
                SELECT * 
                FROM #{self.table.to_s} 
                WHERE COALESCE(#{self.field_time.to_s}, '1900-01-01') < CAST('#{now}' AS TIMESTAMP) - INTERVAL '#{self.max_job_duration_minutes.to_i} minutes' 
                AND #{self.field_id.to_s} IS NOT NULL 
                AND #{self.field_end_time.to_s} IS NULL
                --AND COALESCE(#{self.field_times.to_s},0) < #{self.max_try_times.to_i}
                LIMIT #{n}
              "
              DB[q].all
            end
        
            # returns an array of failed tasks for restarting.
            def relaunching(n)
              if self.relaunching_function.nil?
                return self.relaunching_dataset(n)
              else
                # TODO: validar que retorna un array de strings
                return self.relaunching_function.call(n, self)
              end
            end
            
            def update(o)
              q = "
                UPDATE #{self.table.to_s}
                SET
                  #{self.field_id.to_s} = #{o[self.field_id.to_sym].nil? ? 'NULL' : "'#{o[self.field_id.to_sym]}'"},
                  #{self.field_time} = #{o[self.field_time.to_sym].nil? ? 'NULL' : "'#{o[self.field_time.to_sym].to_s}'"},
                  #{self.field_times} = #{o[self.field_times.to_sym].to_i},
                  #{self.field_start_time} = #{o[self.field_start_time.to_sym].nil? ? 'NULL' : "'#{o[self.field_start_time.to_sym].to_s}'"}, 
                  #{self.field_end_time} = #{o[self.field_end_time.to_sym].nil? ? 'NULL' : "'#{o[self.field_end_time.to_sym].to_s}'"},
                  #{self.field_success} = #{o[self.field_success.to_sym].nil? ? 'NULL' : o[self.field_success.to_sym].to_s},
                  #{self.field_error_description} = #{o[self.field_error_description.to_sym].nil? ? 'NULL' : "'#{o[self.field_error_description.to_sym].to_sql}'"}
                WHERE #{self.field_primary_key} = '#{o[self.field_primary_key.to_sym]}'
              "
              DB.execute(q)
            end

            def relaunch(o)
              o[self.field_id.to_sym] = nil
              o[self.field_time.to_sym] = nil
              o[self.field_start_time.to_sym] = nil if !self.field_start_time.nil?
              o[self.field_end_time.to_sym] = nil if !self.field_end_time.nil?
              self.update(o)
            end
        
            def start(o)
              if self.starter_function.nil?
                o[self.field_start_time.to_sym] = DB["SELECT CAST('#{now}' AS TIMESTAMP) AS dt"].first[:dt] if !self.field_start_time.nil? # IMPORTANT: use DB location to get current time.
                o[self.field_times.to_sym] = o[self.field_times.to_sym].to_i + 1
                self.update(o)
              else
                self.starter_function.call(o, self)
              end
            end
        
            def finish(o, e=nil)
              if self.finisher_function.nil?
                o[self.field_end_time.to_sym] = DB["SELECT CAST('#{now}' AS TIMESTAMP) AS dt"].first[:dt] if !self.field_end_time.nil? && e.nil? # IMPORTANT: use DB location to get current time.
                o[self.field_success.to_sym] = e.nil?
                o[self.field_error_description.to_sym] = e.to_console if !e.nil? 
                self.update(o)
              else
                self.finisher_function.call(o, e, self)
              end
            end
            
            # relaunch records
            def run_relaunch()
              # relaunch failed records
              self.relaunching.each { |o|
                if self.relauncher_function.nil?
                  self.relaunch(o)
                else
                  self.relauncher_function.call(o)
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
                ids = self.selecting(n).map { |h| h[self.field_primary_key.to_sym] }

                i = ids.size

                if i>0
                  q = "
                    UPDATE #{self.table.to_s}
                    SET 
                      #{self.field_id.to_s} = '#{worker.id}', 
                  "

                  if !self.field_start_time.nil?
                    q += "
                    #{self.field_start_time.to_s} = NULL,
                    "
                  end

                  if !self.field_end_time.nil?
                    q += "
                    #{self.field_end_time.to_s} = NULL,
                    "                  
                  end

                  q += "
                    #{self.field_time.to_s} = CAST('#{now}' AS TIMESTAMP)  
                    WHERE #{self.field_primary_key.to_s} IN ('#{ids.join("','")}')
                  "

                  DB.execute(q)
                end # if i>0
              end # if n>0
              
              #      
              return i
            end

            # reporting methods
            # 

            # reporting method: total
            # reutrn the number of total tasks.
            # if the numbr if total tasks is higher than `max_tasks_to_show` then it returns `max_tasks_to_show`+.
            def total
              j = self
              if self.total_function.nil?
                q = "
                    SELECT COUNT(*) AS n
                    FROM #{j.table.to_s} 
                "
                return DB[q].first[:n].to_i
              else
                return self.total_function.call
              end
            end # def total


            # reporting method: completed
            # reutrn the number of completed tasks.
            # if the numbr if completed tasks is higher than `max_tasks_to_show` then it returns `max_tasks_to_show`+.
            def completed
              j = self
              if self.completed_function.nil?
                q = "
                    SELECT COUNT(*) AS n
                    FROM #{j.table.to_s} 
                    WHERE COALESCE(#{j.field_success.to_s},false)=true
                "
                return DB[q].first[:n].to_i
              else
                return self.completed_function.call
              end
            end # def completed

            # reporting method: pending
            # reutrn the number of pending tasks.
            # if the numbr if pending tasks is higher than `max_tasks_to_show` then it returns `max_tasks_to_show`+.
            def pending
                j = self
                if self.pending_function.nil?
                  q = "
                      SELECT COUNT(*) AS n
                      FROM #{j.table.to_s} 
                      WHERE COALESCE(#{j.field_success.to_s},false)=false
                      AND COALESCE(#{j.field_times.to_s},0) < #{j.max_try_times.to_i}
                  "
                  return DB[q].first[:n].to_i
                else
                  return self.pending_function.call
                end
            end # def pending

            # reporting method: running
            # return the number of running tasks.
            # if the number if running tasks is higher than `max_tasks_to_show` then it returns `max_tasks_to_show`+.
            def failed
              j = self
              if self.failed_function.nil?
                q = "
                    SELECT COUNT(*) AS n
                    FROM #{j.table.to_s} 
                    WHERE COALESCE(#{j.field_success.to_s},false)=false
                    AND COALESCE(#{j.field_times.to_s},0) >= #{j.max_try_times.to_i}
                "
                return DB[q].first[:n].to_i
              else
                return self.failed_function.call
              end
            end # def failed
        end # class Job
    end # module Pampa
end # module BlackStack