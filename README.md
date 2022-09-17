
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


1. [Installation](#)
2. [Getting Started]()
    1. [Define a Cluster]()
    2. [Define a Job]()
    3. [Setup Database Connection]()
    4. [Start Processing]()
3. 


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
  :table => Numbers, # Note, that we are sending a class object here
  :field_id => 'odd_checking_reservation_id',
  :field_time => 'odd_checking_reservation_time', 
  :field_times => 'odd_checking_reservation_times',
  :field_start_time => 'odd_checking_start_time',
  :field_end_time => 'odd_checking_end_time',
  
  # Function to execute for each task.
  :processing_function => Proc.new do |job, worker, *args|
    # TODO: Code Me!
  end
})
```

### 2.3. Setting Database Connection

Add this code to your `config.rb` file:

```ruby
require 'sequel'
BlackStack::Pampa.set_connection_string("postgresql://127.0.0.1:26257@db_user:db_pass/blackstack")
```

### 2.4. Setting Output Log File

Add this code to your `config.rb` file:

```ruby
require 'simple_cloud_logging'
BlackStack::Pampa.set_log_filename '~/pampa.log'
```

### 2.5. Deploying Your Cluster

```bash
irb> require_relative './config.rb'
irb> BlackStack::Pampa.deploy
```

### 2.5. Dispatching Tasks

```bash
irb> BlackStack::Pampa.dispatch(:search_odd_numbers)
```

## 3. Watching Cluster Status

```ruby
irb> require_relative './config.rb'
irb> n = BlackStack::Pampa::nodes.first
irb> w = n.workers.first
irb> puts "Last log update: #{w.log_minutes_ago.to_s} mins. ago"
irb> puts "Tasks in queue: #{w.pending_tasks(:search_odd_numbers).to_s}"
```

Here is a script for watching the whole cluster:

```ruby
l = BlackStack::Pampa.logger

l.log 'Workers Status Report:'

BlackStack::Pampa.nodes { |n|
  l.logs "node: #{n.name}... "
  begin
    l.logs 'Connecting... '
    n.connect
    l.done

    n.workers.each { |w|
      l.logs "Worker #{w.id}... "
      begin
        l.logs 'Last log update: ' 
        l.logf "#{w.log_minutes_ago.to_s} mins. ago"

        l.logs 'Tasks in queue: '
        l.logf w.pending_tasks(:search_odd_numbers).to_s

      l.done
      rescue => e
        l.error e
      end
    }

    l.logs 'Disconnect... '
    n.disconnect
    l.done

  l.done
  rescue => e
    l.error e
  end
}
```

## 4. Watching Queues Status

**Pampa**

## 5. Elastic Jobs Processing

Define the maximum tasks tasks allowed.
Define the minumum number of workers assigned for a job.
Define the maximum number of workers assigned for a job.


## 5. Customized Counting Pending Tasks: `:queue_slots_function`

additional function to decide how many records are pending for processing
it should returns an integer
keep it nil if you want to run the default function

## 5. Customized Selecting of Workers: `:allowing_function`

additional function to decide if the worker can dispatch or not
example: use this function when you want to decide based on the remaining credits of the client
it should returns true or false
keep it nil if you want it returns always true

## 6. Customized Selection of Queue Tasks: `:selecting_function`

additional function to choose the records to launch
it should returns an array of IDs
keep this parameter nil if you want to use the default algorithm

## 7. Customized Tasks Relaunching: `:relaunching_function`

additional function to choose the records to retry
keep this parameter nil if you want to use the default algorithm

## 8. Advanced Nodes Connection

**Pampa** uses **SSH** to connect each **node** to deploy **workers**.

If you need advanced features for connecting a **node** (like using a key file instead of password), refer to the [blackstack-nodes documentation](https://github.com/leandrosardi/blackstack-nodes).

## 9. Scheduled Tasks

_(pending)_

## 9. Recurrent Tasks

_(pending)_

## 9. Multi-level Dispatching

_(pending)_

## 

## 8. Setup Resources for Workers

_(pending)_

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

## Inspiration

- [https://dropbox.tech/infrastructure/asynchronous-task-scheduling-at-dropbox](https://dropbox.tech/infrastructure/asynchronous-task-scheduling-at-dropbox)

## Disclaimer

The logo has been taken from [here](https://www.shareicon.net/lines-circles-endpoints-nodes-658150).
