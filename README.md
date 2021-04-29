# Pampa

**Pampa** is a Ruby library for distributing computing providing the following features:

* cluster-management with dynamic reconfiguration (joining and leaving nodes);
* distribution of the computation jobs to the (active) nodes; 
* error handling, job-retry and fault tolerance;
* fast (non-direct) communication to ensure realtime capabilities.

The **Pampa** framework may be widely used for:

* large scale web scraping with what we call a "bot-farm"; 
* payments processing for large-scale ecommerce websites;
* reports generation for high demanded SaaS platforms;
* heavy mathematical model computing; 

and any other tasks that requires a virtually infinite amount of CPU computing and memory resources.

# Installation

```cmd
gem install pampa_workers
```

# 1. Getting Started

This is a short guide to have running a **Pampa worker** who can easily switch between different **child processes**.

You can easily setup, manage and monitor your **Pampa Workers** through our ExpandedVenture's **Threads Service**.

**Additional Note:** As of Apr-21, [**ExpandedVenture**](https://expandedventure.com) is a starting-up holding of SaaS products, like [ConnectionSphere](https://ConnectionSphere.com). Most of its other services are either prototypes or beta.

## 1.1. Getting Your API-KEY

1. Signup to ConnectionSphere here: 
[https://ConnectionSphere.com/signup](https://ConnectionSphere.com/signup)

*(picture pending)*

2. Generate your API-KEY as is explained in this tutorial:
[https://help.expandedventure.com/developers/getting-your-api-key](https://help.expandedventure.com/developers/getting-your-api-key)

## 1.2. Running a Worker

Create a new ruby script `example01.rb` with this little piece of code:

1. Replace `'<write your API-KEY here>'` by your API-KEY.

2. Replace `'connectionsphere.com'` by `'127.0.0.1'` if you are running in your dev environment.

```ruby
require 'pampa_workers'

# parse the command line parameters
parser = BlackStack::SimpleCommandLineParser.new(
  :description => 'This command will launch a Pampa worker.', 
  :configuration => [{
    :name=>'name', 
    :mandatory=>true, 
    :description=>'Name of the worker. Note that the full-name of the worker will be composed with the host-name and the mac-address of the host where the worker is running too; so never 2 workers running in different hosts will have the same name', 
    :type=>BlackStack::SimpleCommandLineParser::STRING,
  }]
)

# setup connection to the Pampa server
BlackStack::Pampa::set_api_url({
  :api_key => '<write your API-KEY here>', # write your API-KEY here
  :api_protocol => 'https',
  :api_domain => 'connectionsphere.com', # use 127.0.0.1 if you are running ConnectionSphere in your dev environment
  :api_port => 443,
})

# map the name of this worker
worker_name = parser.value('name')

# create an instance of the process class
PROCESS = BlackStack::MyParentProcess.new( worker_name, 'local' )

# run the process
PROCESS.run()
```

Then, run the script, as it is shown below:

```cmd
C:> example01 name=my_first_worker
```

The output will look like below,

```cmd
2021-04-28 12:43:45: Hello to the central... done
2021-04-28 12:43:55: Get worker data... done (euler)
2021-04-28 12:44:02: Notify division... done
2021-04-28 12:44:10: Spawn child process... no process assigned
2021-04-28 12:44:10: Sleep...
```

that means that the worker has been registered successfully, but it has not any process assigned yet.

The worker will keep polling our server until it finds it has been assigned with process to run.

## 1.3. Starting a Process

This section is about assigning a process to the worker.

1. Write a child processes.

In the same folder where is your worker `example01.rb`, create a new file `example01-child1.rb`, with the script below.

This is just a dummy process that will print `'Hello World'` in the console.

```ruby
require 'pampa_workers'

# parse the command line parameters
parser = BlackStack::SimpleCommandLineParser.new(
  :description => 'This command will launch a Pampa worker.', 
  :configuration => [{
    :name=>'name', 
    :mandatory=>true, 
    :description=>'Name of the worker. Note that the full-name of the worker will be composed with the host-name and the mac-address of this host too.', 
    :type=>BlackStack::SimpleCommandLineParser::STRING,
  }, {
    :name=>'division', 
    :mandatory=>true, 
    :description=>'Name of the division where this worker is assigned. For more information about divisions, please refer to https://github.com/leandrosardi/tempora#1-architecuture.', 
    :type=>BlackStack::SimpleCommandLineParser::STRING,
  }]
)

# setup connection to the Pampa server
BlackStack::Pampa::set_api_url({
  :api_key => '56D608FC-645D-4A7B-9C38-94C853CADD5A', # write your API-KEY here
  :api_protocol => 'https',
  :api_domain => 'connectionsphere.com',
  :api_port => 443,
})

# child process definition
class MyExampleProcess < BlackStack::MyRemoteProcess  
  def process(argv)
    begin
      puts "Hello World!"
    rescue => e
      puts "ERROR: #{e.to_s}"
    end
  end # process  
end # class 

# map the name of this worker
worker_name = parser.value('name')
division_name = parser.value('division')

# create an instance of the process class
PROCESS = MyExampleProcess.new( worker_name, division_name )

# run the process
PROCESS.run()
```

2. Login to your ConnectionSphere's account here:
[https://ConnectionSphere.com/login](https://ConnectionSphere.com/login).

3. Go to the main list of services here:
[https://euler.connectionsphere.com/main/dashboard](https://euler.connectionsphere.com/main/dashboard).

4. Find the **threads** service, and click on it.
![image](https://i.ibb.co/MBjkBPf/pic1.png)

6. Find your worker in the list, and setup `example01-child1.rb` as its assigned process.

*(It is pending to allow edition of assigned process. Add the sceenshot then.)*

The same worker process that you kept running in the previous section, will detect the new configuraton and run `example01-child1.rb`, who will print `'Hello World!'` in the console.

```cmd
...
...
2021-04-28 13:23:46: Hello to the central... done
2021-04-28 13:23:54: Get worker data... done (euler)
2021-04-28 13:24:01: Notify division... done
2021-04-28 13:24:09: Spawn child process... done (pid=2396)
2021-04-28 13:24:09: Wait to child process to finish.
2021-04-28 13:24:11: Remote process is alive!

2021-04-28 13:24:11: Update from central (1-remote)... done
2021-04-28 13:24:34: Update worker (1-remote)... done
2021-04-28 13:24:48: Switch logger id_client (log folder may change)... done
2021-04-28 13:24:48: Going to Run Remote
2021-04-28 13:24:48: Process: ./examples/example01-child1.rb.
2021-04-28 13:24:49: Client: n/a.

2021-04-28 13:24:49: Release resources... done
2021-04-28 13:24:49: Ping... done
2021-04-28 13:25:05: Notify to Division... done
Hello World!
2021-04-28 13:25:13: Update from central (2)...
```

# 2. Dynamic Reconfiguration  

In this section, you will be able to get your worker switching from one process to the other (**dynamic reconfiguration**).

In the same way you created `example01-child1.rb`, you will create a new file `example01-child2.rb`, who is a very similar process but printing `'Hello ConnectionSphere.com'` instead `'Hello World'`.

Your worker is capable to switch between these 2 **child processes**, when you change its configuraton in the **Threads Service**'s dashboard.

If you update your worker in the **Threads Service**'s dashboard, assigning `example01-child2.rb`, you will see an output like the one shown b

```cmd
...
...
2021-04-28 13:38:02: Going to Run Remote
2021-04-28 13:38:02: Process: ./examples/example01-child1.rb.
2021-04-28 13:38:02: Client: n/a.

2021-04-28 13:38:02: Release resources... done
2021-04-28 13:38:02: Ping... done
2021-04-28 13:38:16: Notify to Division... done
Hello World!
2021-04-28 13:38:24: Update from central (2)... done
2021-04-28 13:38:44: Update worker (2)... done
2021-04-28 13:38:58: Sleep... done
2021-04-28 13:39:02: -------------------------------------------
2021-04-28 13:39:02: Assigned process has changed.
2021-04-28 13:39:02: Sleep... done
2021-04-28 13:39:02: -------------------------------------------

2021-04-28 13:39:02: Hello to the central... done
2021-04-28 13:39:10: Get worker data... done (euler)
2021-04-28 13:39:18: Notify division... done
2021-04-28 13:39:25: Spawn child process... done (pid=6124)
2021-04-28 13:39:25: Wait to child process to finish.
2021-04-28 13:39:26: Remote process is alive!

2021-04-28 13:39:26: Update from central (1-remote)... done
2021-04-28 13:39:43: Update worker (1-remote)... done
2021-04-28 13:39:57: Switch logger id_client (log folder may change)... done
2021-04-28 13:39:57: Going to Run Remote
2021-04-28 13:39:57: Process: ./examples/example01-child2.rb.
2021-04-28 13:39:57: Client: n/a.

2021-04-28 13:39:57: Release resources... done
2021-04-28 13:39:57: Ping... done
2021-04-28 13:40:12: Notify to Division... done
Hello ConnectionSphere.com!
2021-04-28 13:40:19: Update from central (2)... done
2021-04-28 13:40:40: Update worker (2)...
```

# 3. Distributing Jobs

You can run 2 or more workers, with different names, each one in one different consoles.

Example:

**consule 1**,
```cmd
C:\>example01 name=my_worker_01
```

**consule 2**,
```cmd
C:\>example01 name=my_worker_02
```

etc.

You can assign the same process to all workers. Example: all the workers may run `example01-child1.rb`.

When you want to run the same process in parallel, along many workers, you usually want to **distribute** the processing of some repetitive jobs.

Examples: 

- you want to scrape a large list of website; or
- you want to process payments from too many clients at the same time, for a large e-commerce website; or
- you want to compute heavy mathematicall models. 

The assignation of tasks to the different workers is done by a [**dispatcher**](https://github.com/leandrosardi/pampa_dispatcher).

Refer to [Pampa Dispatcher](https://github.com/leandrosardi/pampa_dispatcher) to know how to distribute tasks along many workers.

# 4. Error Handling, Job-Retry and Fault Tolerance

Some kind of processes use to fail time to time.

Example: When you run some processes like web scraping; you may face sporadic errors caused by communication timeouts.

Your [**dispatcher**](https://github.com/leandrosardi/pampa_dispatcher) should be capable to take track the completion of every job, and relaunch if it has not been completed after a certain number of minutes..

Refer to [Pampa Dispatcher](https://github.com/leandrosardi/pampa_dispatcher) to know how to distribute tasks along many workers.

# 5. Further Work

Next features to be added to **Pampa**.

1. Worker Log Monitoring.

2. Worker Screen Streaming.

3. Cloud Dispatcher Configuration & Execution.

4. Cloud Hosting of Workers.


