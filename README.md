
![Gem version](https://img.shields.io/gem/v/pampa) ![Gem downloads](https://img.shields.io/gem/dt/pampa)

![logo](./logo-100.png)

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

## Outline

1. [Installation](#1-installation)
2. [Getting Started](#2-getting-started)
3. [Running Workers](#3-running-workers)
4. [Running Dispatcher](#4-running-dispatcher)
5. [Reporting](#5-reporting)
6. [Custom Dispatching Functions](#6-custom-dispatching-functions)
7. [Custom Reporting Functions](#7-custom-reporting-function)
8. [Elastic Workers Assignation](#8-elastic-workers-assignation)
9. [Further Work](#9-further-work)
10. [Inspiration](#10-inspiration)
11. [Disclaimer](#11-disclaimer)

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
      :name => 'local'
      # setup SSH connection parameters
      :net_remote_ip => '127.0.0.1',  
      :ssh_username => '<your ssh username>', # example: root
      :ssh_port => 22,
      :ssh_password => '<your ssh password>',
      # setup max number of worker processes
      :max_workers => 1,
    },
  ]
)
```

## 5. Define a Job

A **job** is a sequence of **tasks**. 

Each **task** performs the same **function** on different records of a table.

The code below is for processing all records into a table `numbers`, and update the field `is_odd` with `true` or `false`.

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
    l.logs 'Checking if '+task[:value].to_s+' is odd... '
    if task[:value] % 2 == 0
      task[:is_odd] = false
      l.logf 'No.'.red
    else
      task[:is_odd] = true
      l.logf 'Yes.'.green
    end
  end
})
```

## 6. Setup Your Database

Obviously, you have to create the table in your database.
And you have to insert some seed data too.

[Here is the PostgreSQL script you have to run the example in this tutorial](https://github.com/leandrosardi/pampa/blob/master/examples/demo.sql).

## 7. Connect To Your Database

In order to operate with the table `numbers`, you have to connect **Pampa** to your database.

Add this code to your `config.rb` file:

```ruby
# DB ACCESS - KEEP IT SECRET
# Connection string to the demo database: export DATABASE_URL='postgresql://demo:<ENTER-SQL-USER-PASSWORD>@free-tier14.aws-us-east-1.cockroachlabs.cloud:26257/mysaas?sslmode=verify-full&options=--cluster%3Dmysaas-demo-6448'
BlackStack::PostgreSQL::set_db_params({ 
  :db_url => '89.116.25.250', # n04
  :db_port => '5432', 
  :db_name => 'micro.data', 
  :db_user => 'blackstack', 
  :db_password => '*****',
  :db_sslmode => 'disable',
})
```

## 8. Running Dispatcher

The **dispatcher** will run an infinite loop, assigning tasks to each **worker** at each iteration of such a loop. 

**Step 1:** Create your `dispatcher.rb` script-file.

```
touch ~/dispatcher.rb
```

**Step 2:** Write this code into your `dispatcher.rb` file.

```ruby
require `pampa/dispatcher`
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

## 9. Running Workers

The **worker** will run an infineet loop, processing all assigned tasks at each iteration of such a loop. 

**Step 1:** Create a new file `worker.rb` file.

```
touch ~/worker.rb
```

**Step 2:** Write this code into your `worker.rb` file.

```ruby
require `pampa/worker`
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

## 10. Selection Snippet

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
  :filter_worker_id => /.*/,
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
  end,

  # write a snippet for selecting records to dispatch.
  :selecting_function => Proc.new do |n, *args|
    DB["
      SELECT *
      FROM numbers
      WHERE odd_checking_reservation_id IS NULL           -- record not reserved yet
      AND odd_checking_start_time IS NULL                 -- record is not pending to relaunch
      AND COALESCE(odd_checking_reservation_times,0) < 3  -- record didn't fail more than 3 times
      ORDER BY number DESC                                -- I want to order by number reversely
      LIMIT #{n}                                          -- don't dispatch more than n records at the time
    "].all
  end,
})
```

**Example:** You define another **job** to submit processed numbers a server.

**Other Examples:**

- You want to deliver emails of active email campaigns only (`active=true`).
- 







## 5. Reporting

_(pending to develop this method)_

## 6. Custom Dispatching Functions

_(pending to write this section)_


### 6.2. Relaunching: `:relaunching_function`

You may want to re-processes recurrently every few minutes or hours. 
For example, you may want to monitor servers.

additional function to choose the records to retry
keep this parameter nil if you want to use the default algorithm

## 7. Elastic Workers Assignation

_(pending to write this section)_

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
    :max_workers => 1,
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
