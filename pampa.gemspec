Gem::Specification.new do |s|
  s.name        = 'pampa'
  s.version     = '2.0.24'
  s.date        = '2022-02-08'
  s.summary     = "Ruby library for async & distributed computing, supporting dynamic reconfiguration, distribution of the computation jobs, error handling, job-retry and fault tolerance, and fast (non-direct) communication to ensure real-time capabilities."
  s.description = "Pampa is a Ruby library for async & distributing computing providing the following features:

- cluster-management with dynamic reconfiguration (joining and leaving nodes);
- distribution of the computation jobs to the (active) nodes;
- error handling, job-retry and fault tolerance;
- fast (non-direct) communication to ensure realtime capabilities.

The Pampa framework may be widely used for:

- large scale web scraping with what we call a \"bot-farm\";
- payments processing for large-scale ecommerce websites;
- reports generation for high demanded SaaS platforms;
- heavy mathematical model computing;

and any other tasks that requires a virtually infinite amount of CPU computing and memory resources.

Find documentation here: https://github.com/leandrosardi/pampa
"
  s.authors     = ["Leandro Daniel Sardi"]
  s.email       = 'leandro.sardi@expandedventure.com'
  s.files       = [
    'worker.rb',
    'lib/pampa.rb',
  ]
  s.homepage    = 'https://rubygems.org/gems/pampa'
  s.license     = 'MIT'
  s.add_runtime_dependency 'sequel', '~> 5.56.0', '>= 5.56.0'
  s.add_runtime_dependency 'blackstack-core', '~> 1.2.3', '>= 1.2.3'
  s.add_runtime_dependency 'blackstack-nodes', '~> 1.2.11', '>= 1.2.11'
  s.add_runtime_dependency 'blackstack-deployer', '~> 1.2.24', '>= 1.2.24'
  s.add_runtime_dependency 'simple_command_line_parser', '~> 1.1.2', '>= 1.1.2'
  s.add_runtime_dependency 'simple_cloud_logging', '~> 1.2.2', '>= 1.2.2'
end