
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

## Outline

- [Installation](#)
1. [Getting Started]()

    - [Define a Cluster]()
    - [Define a Job]()
    - [Start Processing]()

2. 


## Installation

```cmd
gem install pampa
```

## 1. Getting Started

This example set up a **cluster** of **worker** processes to process all the numbers from 1 to 100,000; and build the list of odd numbers inside such a range.

**Important:** For working with a very large set of values (example: `(1..10**500000)`), refer to section [2. Working with Very Large Set of Values](???).

### Define a Cluster

First, you have to define a **cluster** of **workers**.

- A **cluster** is composed by one or more **nodes** (computers).

- Each **worker** is a process running on a node.

The code below define your computer as a **node** of 10 **workers**. 

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

### Define a Job

A **job** is a sequence of **tasks**. 

Each **task** performs the same **function** on a different record.

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

### Launch

```ruby
# this line is for starting the workers
BlackStack::Pampa.deploy

# this line is dispatch tasks to the workers
while true
  BlackStack::Pampa.dispatch(:search_odd_numbers)
end
```

## 2. Elastic Jobs Jobs

Define the maximum tasks tasks allowed.
Define the minumum number of workers assigned for a job.
Define the maximum number of workers assigned for a job.


## 3. Define the Output Log File

```ruby
BlackStack::Pampa.set_log_filename '~/pampa.log'
```

## 4. Customized Counting Pending Tasks: `:queue_slots_function`

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
