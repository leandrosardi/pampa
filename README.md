
![Gem version](https://img.shields.io/gem/v/pampa) ![Gem downloads](https://img.shields.io/gem/dt/pampa)

![logo](./logo-100.png)

# Pampa - Async & Distributed Data Processing

**Pampa** is a Ruby library for async & distributing computing providing the following features:

- cluster-management with dynamic reconfiguration (joining and leaving nodes);
- distribution of the computation jobs to the (active) nodes;
- error handling, job-retry, and fault tolerance;
- fast (non-direct) communication to ensure real-time capabilities.

The **Pampa** framework may be widely used for:

- large scale web scraping with what we call a "bot-farm";
- payments processing for large-scale eCommerce websites;
- reports generation for highly demanded SaaS platforms;
- heavy mathematical model computing;

and any other tasks that require a virtually infinite amount of CPU computing and memory resources.

As a final words, **Pampa** supports [PostrgreSQL](https://www.postgresql.org) and [CockroachDB](https://www.cockroachlabs.com).

## Outline

1. [Installation](#1-installation)
2. [Getting Started](#2-getting-started)
    1. [Define a Cluster](#21-defining-clusters)
    2. [Define a Job](#22-defining-jobs)
    3. [Setup Database Connection](#23-setting-database-connection)
    4. [Start Processing](#24-setting-output-log-file)
3. [Running Workers](#3-running-workers)
4. [Running Dispatcher](#4-running-dispatcher)

## 1. Installation

```cmd
gem install pampa
```

## 2. Getting Started

This example set up a **cluster** of **worker** processes to process all the numbers from 1 to 100,000; and build the list of odd numbers inside such a range.

Create a new file `~/config.rb` where you will define your **cluster**, **jobs**, **database connection** and **logging**.

```bash
touch ~/config.rb
```

### 2.1. Defining Clusters

First, you have to define a **cluster** of **workers**.

- A **cluster** is composed by one or more **nodes** (computers).

- Each **worker** is a process running on a node.

The code below define your computer as a **node** of 10 **workers**. 

Add this code to your `config.rb` file:

```ruby
require 'pampa'

# setup one or more nodes (computers) where to launch worker processes
n = BlackStack::Pampa.add_nodes(
  [
    {
      :name => 'local'
      # setup SSH connection parameters
      :net_remote_ip => '127.0.0.1',  
      :ssh_username => '<your ssh username>', # example: root
      :ssh_port => 22,
      :ssh_password => '<your ssh password>',
      # setup max number of worker processes
      :max_workers => 10,
    },
  ]
)
```

### 2.2. Defining Jobs

A **job** is a sequence of **tasks**. 

Each **task** performs the same **function** on a different record.

Add this code to your `config.rb` file:

```ruby
# setup the cluster
BlackStack::Pampa.add_job({
  :name => 'search_odd_numbers',

  # Minimum number of tasks that a worker must have in queue.
  # Default: 5
  :queue_size => 5, 
  
  # Maximum number of minutes that a task should take to process.
  # If a tasks didn't finish X minutes after it started, it is restarted and assigned to another worker.
  # Default: 15
  :max_job_duration_minutes => 15,  
  
  # Maximum number of times that a task can be restarted.
  # Default: 3
  :max_try_times => 3,

  # Define the tasks table: each record is a task.
  # The tasks table must have some specific fields for handling the tasks dispatching.
  :table => :numbers, # Note, that we are sending a class object here
  :field_primary_key => :value,
  :field_id => :odd_checking_reservation_id,
  :field_time => :odd_checking_reservation_time, 
  :field_times => :odd_checking_reservation_times,
  :field_start_time => :odd_checking_start_time,
  :field_end_time => :odd_checking_end_time,
  :field_success => :odd_checking_success,
  :field_error_description => :odd_checking_error_description,

  # Function to execute for each task.
  :processing_function => Proc.new do |task, l, job, worker, *args|
    # TODO: Code Me!
  end
})
```

### 2.3. Setting Database Connection

Add this code to your `config.rb` file:

```ruby
BlackStack::Pampa.set_connection_string("postgresql://127.0.0.1:26257@db_user:db_pass/blackstack")
```

### 2.4. Setting Output Log File

Add this code to your `config.rb` file:

```ruby
require 'simple_cloud_logging'
BlackStack::Pampa.set_log_filename '~/pampa.log'
```

## 3. Running Workers

```ruby
require 'pampa'
require_relative './config'

# grab a worker
worker = BlackStack::Pampa.workers.select { |w| w.id == 'local.1' }.first

# grab a job
job = BlackStack::Pampa.jobs.select { |j| j.name == 'search_odd_numbers' }.first

# grab tasks assigned to this worker
tasks = job.occupied_slots(worker)

# flag task as started
job.start(task)

begin
  # perform task
  job.processing_function.call(task, l, job, worker)

  # flag task as finished successfully
  job.finish(task)
rescue => e
  # flag task as finished with error
  job.finish(task, e)
end
```

## 4. Running Dispatcher

```ruby
require 'pampa'
require_relative './config'

# assign workers to each job
BlackStack::Pampa.stretch

# relaunch expired tasks
BlackStack::Pampa.relaunch
        
# dispatch tasks to each worker
BlackStack::Pampa.dispatch
```

## 5. Watching the Status of a Worker

_(this feature is pending to develop)_

```ruby
irb> require_relative './config.rb'
irb> n = BlackStack::Pampa::nodes.first
irb> w = n.workers.first
irb> puts "Last log update: #{w.log_minutes_ago.to_s} mins. ago"
```

Here is [an example](./examples/watching.rb) of watching all the workers of the cluster.

## 6. Watching the Queue of a Worker

_(this feature is pending to develop)_

```ruby
irb> require_relative './config.rb'
irb> n = BlackStack::Pampa::nodes.first
irb> w = n.workers.first
irb> puts "Tasks in queue: #{w.pending_tasks(:search_odd_numbers).to_s}"
```

Here is [an example](./examples/watching.rb) of watching all the workers of the cluster.

## 7. Suspending Workers and Clusters

_(this feature is pending to develop)_

```ruby
irb> require_relative './config.rb'
irb> n = BlackStack::Pampa::nodes.first
irb> n.stop
```

```ruby
irb> n.start
```

```ruby
irb> w = n.workers.first
irb> w.stop
```

```ruby
irb> w.start
```

## 8. Elastic Jobs Processing

_(this feature is pending to develop)_

Define the maximum tasks tasks allowed.
Define the minumum number of workers assigned for a job.
Define the maximum number of workers assigned for a job.

## 10. Customized Counting Pending Tasks: `:occupied_function`

_(this feature is pending to develop)_

The `:occupied_function` function returns an array with the pending **tasks** in queue for a **worker**.

The default function returnss all the **tasks** with `:field_id` equel to the name of the worker, and the `:field_start_time` empty.

You can setup a custom version of this function.

Example: You may want to sort 

additional function to decide how many records are pending for processing
it should returns an integer
keep it nil if you want to run the default function

## 11. Customized Selecting of Workers: `:allowing_function`

_(this feature is pending to develop)_

additional function to decide if the worker can dispatch or not
example: use this function when you want to decide based on the remaining credits of the client
it should returns true or false
keep it nil if you want it returns always true

## 12. Customized Selection of Queue Tasks: `:selecting_function`

additional function to choose the records to launch
it should returns an array of IDs
keep this parameter nil if you want to use the default algorithm

## 13. Customized Tasks Relaunching: `:relaunching_function`

additional function to choose the records to retry
keep this parameter nil if you want to use the default algorithm

## 14. Advanced Nodes Connection

**Pampa** uses **SSH** to connect each **node** to deploy **workers**.

If you need advanced features for connecting a **node** (like using a key file instead of password), refer to the [blackstack-nodes documentation](https://github.com/leandrosardi/blackstack-nodes).

## 15. Scheduled Tasks

_(this feature is pending to develop)_

## 16. Recurrent Tasks

_(this feature is pending to develop)_

## 17. Multi-level Dispatching

_(this feature is pending to develop)_

## 18. Setup Resources for Workers

_(this feature is pending to develop)_

```ruby
# setup nodes (computers) where to launch
n = BlackStack::Pampa.add_nodes([{
    # setup SSH connection parameters
    :net_remote_ip => '54.160.137.218',  
    :ssh_username => 'ubuntu',
    :ssh_port => 22,
    :ssh_private_key_file => './plank.pem',
    # setup max number of worker processes
    :max_workers => 10,
    # setup max memory consumption per worker (MBs)
    :max_ram => 512, 
    # setup max CPU usage per worker (%)
    :max_cpu => 10,
    # setup max disk I/O per worker (mbps)
    :max_disk_io => 1000,
    # setup max ethernet I/O per worker (mbps)
    :max_net_io => 1000,

}])
```

## 19. Inspiration

- [https://dropbox.tech/infrastructure/asynchronous-task-scheduling-at-dropbox](https://dropbox.tech/infrastructure/asynchronous-task-scheduling-at-dropbox)

## 20. Disclaimer

The logo has been taken from [here](https://icons8.com/icon/ay4lYdOUt1Vd/geometric-figures).
