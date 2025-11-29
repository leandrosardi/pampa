
![Gem version](https://img.shields.io/gem/v/pampa) ![Gem downloads](https://img.shields.io/gem/dt/pampa)

# Pampa - Async & Distributed Data Processing

**Pampa** is a Ruby library for async & distributed computing, providing the following features:

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

As a final words, **Pampa** supports [PostrgreSQL](https://www.postgresql.org) and [CockroachDB](https://www.cockroachlabs.com), and it has been tested on [Ubuntu 18.04](https://releases.ubuntu.com/18.04/) and [Ruby 3.1.2p20](https://www.ruby-lang.org/en/news/2022/04/12/ruby-3-1-2-released/).

**Outline**

1. [Installation](#1-installation)
2. [Getting Started](#2-getting-started)
3. [Define Your Cluster](#3-define-your-cluster)
4. [Define a Job](#4-define-a-job)
5. [Setup Your Database](#5-setup-your-database)
6. [Connect To Your Database](#6-connect-to-your-database)
7. [Running Dispatcher](#7-running-dispatcher)
8. [Running Workers](#8-running-workers)
9. [Selection Snippet](#9-selection-snippet)
10. [Relaunching Snippet](#10-relaunching-snippet)
11. [Elastic Workers Assignation](#11-elastic-workers-assignation)
12. [Reporting](#12-reporting)
13. [Stand Alone Processes](#13-stand-alone-processes)

## 1. Installation

```cmd
gem install pampa
```

## 2. Getting Started

This example set up a **cluster** of **workers** to process all the numbers from 1 to 100,000; and build the list of odd numbers inside such a range.

Create a new file `~/config.rb` where you will define your **cluster**, **jobs**, **database connection** and **logging**.

```bash
touch ~/config.rb
```

Additionally, you may want to add the path `~` to your the environment varaible `RUBYLIB`, in order to require the `config.rb` file from your Ruby code.

```bash
export RUBYLIB=~
```

## 3. Define Your Cluster

As a first step, you have to define a **cluster** of **workers**.

- A **cluster** is composed by one or more **nodes** (computers).

- Each **worker** is a process running on a **node**.

The code below define your computer as a **node** of 10 **workers**. 

Add this code to your `config.rb` file:

```ruby
# setup one or more nodes (computers) where to launch worker processes
BlackStack::Pampa.add_nodes(
  [
    {
      :name => 'local',
      # setup SSH connection parameters
      :net_remote_ip => '127.0.0.1',  
      :ssh_username => '<your ssh username>', # example: root
      :ssh_port => 22,
      :ssh_password => '<your ssh password>',
      # setup max number of worker processes
      :max_workers => 2,
    },
  ]
)
```

## 4. Define a Job

A **job** is a sequence of **tasks**. 

Each **task** performs the same **function** on different records of a table.

The code below is for processing all records into a table `numbers`, and update the field `is_odd` with `true` or `false`.

Add this code to your `config.rb` file:

```ruby
# setup the cluster
BlackStack::Pampa.add_job({
  :name => 'search_odd_numbers',

  # any worker can be assigned for processing this job.
  :filter_worker_id => /.*/,
  
  # no more than 5 workers can be assigned for processing this job.
  :max_assigned_workers => 5,
      
  # add more workers if the number of pending tasks is over 5.
  :max_pending_tasks => 500,

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
    l.logs 'Checking if '+task[:value].to_s+' is odd... '
    if task[:value] % 2 == 0
      task[:is_odd] = false
      l.logf 'No.'.red
    else
      task[:is_odd] = true
      l.logf 'Yes.'.green
    end
    DB[:numbers].where(:value=>task[:value]).update(:is_odd=>task[:is_odd])
  end
})
```

## 5. Setup Your Database

Obviously, you have to create the table in your database.
And you have to insert some seed data too.

[Here is the PostgreSQL script you have to run the example in this tutorial](https://github.com/leandrosardi/pampa/blob/master/examples/demo.sql).

## 6. Connect To Your Database

In order to operate with the table `numbers`, you have to connect **Pampa** to your database.

Add this code to your `config.rb` file:

```ruby
# DB ACCESS - KEEP IT SECRET
# Connection string to the demo database: export DATABASE_URL='postgresql://demo:<ENTER-SQL-USER-PASSWORD>@free-tier14.aws-us-east-1.cockroachlabs.cloud:26257/mysaas?sslmode=verify-full&options=--cluster%3Dmysaas-demo-6448'
BlackStack::PostgreSQL::set_db_params({ 
  :db_url => '89.116.25.250', # n04
  :db_port => '5432', 
  :db_name => 'micro.data', 
  :db_user => 'your-name', 
  :db_password => 'your-password',
  :db_sslmode => 'disable',
})
```

## 7. Running Dispatcher

The **dispatcher** will run an infinite loop, assigning tasks to each **worker** at each iteration of such a loop. 

**Step 1:** Create your `dispatcher.rb` script-file.

```
touch ~/dispatcher.rb
```

**Step 2:** Write this code into your `dispatcher.rb` file.

```ruby
require 'pampa/dispatcher'
```

**Step 3:** Run the dispatcher.

Run the command below on your `local` node in order to run your worker.

```
export RUBYLIB=~/
ruby ~/dispatcher.rb
```

**Parameters:**

1. **delay:** You may set the delay in seconds between iterations:

```
ruby ~/dispatcher.rb delay=30
```

2. **config:** Be default, `dispatcher.rb` will `require 'config.rb'`. That is why you have to execute `export RUBYLIB=~/` before running the dispatcher. Though, you can define a custom location of the configuration file too.

```
ruby ~/dispatcher.rb config=~/foo/config.rb
```

3. **db:** Use this parameters to choose a database driver. The supported values are: `postgres`, `crdb`. By default, it is: `postgres`.

```
ruby ~/dispatcher.rb db=crdb
```

4. **log:** Use this parameter to indicate the process to write the log in the file `./dispatcher.log` or not. The default value is `yes`.

```
ruby ~/dispatcher.rb log=no
```

**Code Snippets:**

You can define a code to be executed right after **dispatcher** connected to the database.

Add a code like this in your `config.rb` file.

```ruby
# Pampa Code Snippets
BlackStack::Pampa.set_snippets({
  :dispatcher_function => Proc.new do |l, *args|
    require 'my-project/model'
  end,
})
```

You can also pass a logger to the snippet.

```ruby
# Pampa Code Snippets
BlackStack::Pampa.set_snippets({
  :dispatcher_function => Proc.new do |l, *args|
    l = BlackStack::DummyLogger.new(nil) if l.nil?

    l.logs 'Loading model.. '
    require 'my-project/model'
    l.logf 'done'.green
  end,
})
```

## 8. Running Workers

The **worker** will run an infineet loop, processing all assigned tasks at each iteration of such a loop. 

**Step 1:** Create a new file `worker.rb` file.

```
touch ~/worker.rb
```

**Step 2:** Write this code into your `worker.rb` file.

```ruby
require 'pampa/worker'
```

**Step 3:** Run a worker.

Run the command below on your `local` node in order to run your worker.

```
export RUBYLIB=~/
ruby ~/worker.rb id=localhost.1
```

**Parameters:**

1. **delay:** You may set the delay in seconds between iterations:

```
ruby ~/worker.rb id=localhost.1 delay=30
```

2. **config:** Be default, `worker.rb` will `require 'config.rb'`. That is why you have to execute `export RUBYLIB=~/` before running the dispatcher. Though, you can define a custom location of the configuration file too.

```
ruby ~/worker.rb id=localhost.1 config=~/foo/config.rb
```

3. **db:** Use this parameters to choose a database driver. The supported values are: `postgres`, `crdb`. By default, it is: `postgres`.

```
ruby ~/worker.rb id=localhost.1 db=crdb
```

4. **log:** Use this parameter to indicate the process to write the log in the file `./worker.#{id}.log` or not. The default value is `yes`.

```
ruby ~/worker.rb id=localhost.1 log=no
```

**Code Snippets:**

You can define a code to be executed right after **worker** connected to the database.

Add a code like this in your `config.rb` file.

```ruby
# Pampa Code Snippets
BlackStack::Pampa.set_snippets({
  :dispatcher_function => Proc.new do |l, *args|
    initialize_scraper()
  end,
})
```

You can also pass a logger to the snippet.

```ruby
# Pampa Code Snippets
BlackStack::Pampa.set_snippets({
  :dispatcher_function => Proc.new do |l, *args|
    l = BlackStack::DummyLogger.new(nil) if l.nil?

    l.logs 'Initializing scraper... '
    initialize_scraper()
    l.logf 'done'.green
  end,
})
```

## 9. Selection Snippet

You can re-write the default function used by the **dispatcher** to choose the records it will assign to the **workers**.

**Example:** You want to dispatch the records in the table `numbers`, but sorted by `value` reversely.

```ruby
# define the job
BlackStack::Pampa.add_job({
  :name => 'search_odd_numbers',
  :queue_size => 5, 
  :max_job_duration_minutes => 15,  
  :max_try_times => 3,
  :table => :numbers, # Note, that we are sending a class object here
  :field_primary_key => :value,
  :field_id => :odd_checking_reservation_id,
  :field_time => :odd_checking_reservation_time, 
  :field_times => :odd_checking_reservation_times,
  :field_start_time => :odd_checking_start_time,
  :field_end_time => :odd_checking_end_time,
  :field_success => :odd_checking_success,
  :field_error_description => :odd_checking_error_description,
  :filter_worker_id => /\.1$/, # only worker number 1 will receive tasks of this job.
  :max_pending_tasks => 10, 
  :max_assigned_workers => 5, 
  :processing_function => Proc.new do |task, l, job, worker, *args|
    l.logs 'Checking if '+task[:value].to_s.blue+' is odd... '
    if task[:value] % 2 == 0
      task[:is_odd] = false
      l.logf 'No.'.yellow
    else
      task[:is_odd] = true
      l.logf 'Yes.'.green
    end
    DB[:numbers].where(:value=>task[:value]).update(:is_odd=>task[:is_odd])
  end,

  # write a snippet for selecting records to dispatch.
  :selecting_function => Proc.new do |n, *args|
    DB["
      SELECT *
      FROM numbers
      WHERE odd_checking_reservation_id IS NULL           -- record not reserved yet
      AND odd_checking_start_time IS NULL                 -- record is not pending to relaunch
      AND COALESCE(odd_checking_reservation_times,0) < 3  -- record didn't fail more than 3 times
      ORDER BY value DESC                                -- I want to order by number reversely
      LIMIT #{n}                                          -- don't dispatch more than n records at the time
    "].all
  end,
})
```

**Example:** You define another **job** to submit the odd numbers to a server.

```ruby
# define the job
BlackStack::Pampa.add_job({
  :name => 'submit_odd_numbers',
  :queue_size => 5, 
  :max_job_duration_minutes => 15,  
  :max_try_times => 3,
  :table => :numbers, # Note, that we are sending a class object here

  :field_primary_key => :value,
  :field_id => :submit_odd_reservation_id,
  :field_time => :submit_odd_reservation_time, 
  :field_times => :submit_odd_reservation_times,
  :field_start_time => :submit_odd_start_time,
  :field_end_time => :submit_odd_end_time,
  :field_success => :submit_odd_success,
  :field_error_description => :submit_odd_error_description,
  
  :filter_worker_id => /\.2/,
  
  :max_pending_tasks => 10, 
  :max_assigned_workers => 5, 
  
  :processing_function => Proc.new do |task, l, job, worker, *args|
    # TODO: Run a post call here, to subit the record.
  end,

  # write a snippet for selecting records to dispatch.
  :selecting_function => Proc.new do |n, *args|
    DB["
      SELECT *
      FROM numbers
      WHERE submit_odd_reservation_id IS NULL             -- record not reserved yet
      AND submit_odd_start_time IS NULL                   -- record is not pending to relaunch
      AND COALESCE(submit_odd_reservation_times,0) < 3    -- record didn't fail more than 3 times

      AND odd_checking_end_time IS NOT NULL               -- record that have been checked
      AND COALESCE(odd_checking_success, FALSE) = TRUE    -- record that have been checked successfully
      AND COALESCE(id_odd, FALSE) = TRUE                  -- only submit odd values

      ORDER BY odd_checking_end_time DESC                 -- submit records in the order they have been checked
      LIMIT #{n}                                          -- don't dispatch more than n records at the time
    "].all
  end,
})
```

**Other Examples:**

- You may want to deliver emails of active email campaigns only (`active=true`).
- You may want to process orders in the order they have been created (`order by create_time`).
- You may want to add a delay of 1 day from the moment a new user signed up and he/she receives an email notification.

## 10. Relaunching Snippet

Use `:relaunching_function` to write your own snippet code that will choose the records you want to relaunch.

**Example:** You may want to check if each number is still odd every 10 minutes, because you are afraid the laws of the universe have suddenly changed

```ruby
# define the job
BlackStack::Pampa.add_job({
  :name => 'search_odd_numbers',
  :queue_size => 5, 
  :max_job_duration_minutes => 15,  
  :max_try_times => 3,
  :table => :numbers, # Note, that we are sending a class object here
  :field_primary_key => :value,
  :field_id => :odd_checking_reservation_id,
  :field_time => :odd_checking_reservation_time, 
  :field_times => :odd_checking_reservation_times,
  :field_start_time => :odd_checking_start_time,
  :field_end_time => :odd_checking_end_time,
  :field_success => :odd_checking_success,
  :field_error_description => :odd_checking_error_description,
  :filter_worker_id => /\.1$/, # only worker number 1 will receive tasks of this job.
  :max_pending_tasks => 10, 
  :max_assigned_workers => 5, 
  :processing_function => Proc.new do |task, l, job, worker, *args|
    l.logs 'Checking if '+task[:value].to_s.blue+' is odd... '
    if task[:value] % 2 == 0
      task[:is_odd] = false
      l.logf 'No.'.yellow
    else
      task[:is_odd] = true
      l.logf 'Yes.'.green
    end
    DB[:numbers].where(:value=>task[:value]).update(:is_odd=>task[:is_odd])
  end,

  # you want to check if each number is still odd every 10 minutes, 
  # because you are afraid the laws of the universe have suddenly changed.
  :relaunching_function => Proc.new do |n, *args|
    DB["
      SELECT *
      FROM numbers
      WHERE odd_checking_end_time IS NOT NULL                                           -- record that have been checked
      AND odd_checking_end_time < CAST('#{now}' AS TIMESTAMP) - INTERVAL '10 MINUTES'   -- checked 10 minutes ago
      LIMIT #{n}                                                                        -- don't relaunch more than n records at the time
    "].all
  end,
})
```

**Other Examples:**

- Every 5 minutes you want to check if a list of websites are online.
- You want to trace the CPU usage of a pool of servers.
- You want to keep mirroring infromation between databases.

## 11. Elastic Workers Assignation

The **dispatcher** process not only assign **tasks** to **workers**, but it also **assign** and **unassign** **workers** to each **job**, depending on the number of **task** in **queue** for such a **job**.

When you define a job, 

- use the parameter `:max_pending_tasks` to tell the dispatcher when it should assign more workers for this job. If the number of pending task is higer than `:max_pending_tasks`, the dispatcher will scale the number of assigned workers;

- but also use the parameter `:max_assigned_workers` to prevent your job to monopolize the entire pool of workers and get in the way of other jobs if its number of pending tasks raises so high;

and finally,

- you can use the `:filter_worker_id` to define a regular expession to filter the workers that may be assigned for your job. E.g.: Use `/.*/` to allow any worker to be assigned, or use `/\.1$/` to allow the first worker in each node to be assigned only.

## 12. Reporting

You can get the number of 

- total tasks,
- completed task,
- pending tasks,
and
- failed tasks;

calling the methods shown below.

```ruby
j = BlackStack::Pampa.jobs.first

p j.name

p j.total.to_label
p j.completed.to_label
p j.pending.to_label
p j.failed.to_label
```

If you wrote snippets for either selecting or relaunching records, you may need to write sneeppets for the reporting methods too, in order to make their numbers congruent.

```ruby
# define the job
BlackStack::Pampa.add_job({
  :name => 'search_odd_numbers',

  # ...

  :total_function => Proc.new do |*args|
    # TODO: return a number here
  end,

  :completed_function => Proc.new do |*args|
    # TODO: return a number here
  end,

  :pending_function => Proc.new do |*args|
    # TODO: return a number here
  end,

  :completed_function => Proc.new do |*args|
    # TODO: return a number here
  end,

})
```

## Inspiration

- [https://dropbox.tech/infrastructure/asynchronous-task-scheduling-at-dropbox](https://dropbox.tech/infrastructure/asynchronous-task-scheduling-at-dropbox)

## Disclaimer

The logo has been taken from [here](https://icons8.com/icon/ay4lYdOUt1Vd/geometric-figures).

Use this library at your own risk.

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the last [ruby gem](https://rubygems.org/gems/simple_command_line_parser). 

## Authors

* **Leandro Daniel Sardi** - *Initial work* - [LeandroSardi](https://github.com/leandrosardi)

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

## Further Work

### Counting Pending Tasks: `:occupied_function`

The `:occupied_function` function returns an array with the pending **tasks** in queue for a **worker**.

The default function returns all the **tasks** with `:field_id` equal to the name of the worker, and the `:field_start_time` empty.

You can setup a custom version of this function.

Example: You may want to sort ....

additional function to decide how many records are pending for processing
it should returns an integer
keep it nil if you want to run the default function

### Selecting of Workers: `:allowing_function`

_(this feature is pending to develop)_

additional function to decide if the worker can dispatch or not
example: use this function when you want to decide based on the remaining credits of the client
it should returns true or false
keep it nil if you want it returns always true

### Scheduled Tasks

_(this feature is pending to develop)_

### Multi-level Dispatching

_(this feature is pending to develop)_

### Setup Resources for Workers

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
    :max_workers => 2,
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

## 13. Stand Alone Processes

Pampa provides a standard framework for running stand-alone processes too.

Use the function `run_stand_alone` for processing recursivelly, every some seconds.

**Example:**

```ruby
require 'pampa'

DELAY = 10 # seconds
ONCE = false # if false, execute this process every DELAY seconds

BlackStack::Pampa.run_stand_alone({
    :log_filename => 'example.log',
    :delay => DELAY,
    :run_once => ONCE,
    :function => Proc.new do |l, *args|
        begin
            l.log 'Hello, World!'

            l.log "1. Executing this process recursively, with a timeframe of #{DELAY} seconds between the starting of each one."
            l.log "2. If an execution takes more than #{DELAY} seconds, the next execution will start immediatelly."
            l.log "3. If an error occurs, the process will stop. So be sure to catch all exceptions here."

            # your code here

        rescue => e
            l.logf "Error: #{e.to_console.red}"
        # CTRL+C will be catched here
        rescue Interrupt => e
            l.logf "Interrupted".red
            exit(0)
        ensure
            l.log "End of the process."
        end
    end, 
})
```

