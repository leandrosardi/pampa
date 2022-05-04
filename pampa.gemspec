Gem::Specification.new do |s|
  s.name        = 'pampa_workers'
  s.version     = '1.1.39'
  s.date        = '2022-05-04'
  s.summary     = "THIS GEM IS STILL IN DEVELOPMENT STAGE. Ruby library for distributing computing, supporting dynamic reconfiguration, distribution of the computation jobs, error handling, job-retry and fault tolerance, fast (non-direct) communication to ensure real-time capabilities."
  s.description = "THIS GEM IS STILL IN DEVELOPMENT STAGE. Find documentation here: https://github.com/leandrosardi/pampa."
  s.authors     = ["Leandro Daniel Sardi"]
  s.email       = 'leandro.sardi@expandedventure.com'
  s.files       = [
    'lib/pampa_workers.rb',
    'lib/pampa-local.rb',
    'lib/params.rb',
    'lib/basedivision.rb',
    'lib/baseworker.rb',
    'lib/division.rb',
    'lib/worker.rb',
    'lib/remotedivision.rb',
    'lib/remoteworker.rb',
    'lib/myprocess.rb',
    'lib/myparentprocess.rb',
    'lib/myremoteprocess.rb',
    'lib/mychildprocess.rb',
    'lib/mylocalprocess.rb',
    'lib/mycrawlprocess.rb',
    'lib/client.rb',
    'lib/timezone.rb',
    'lib/user.rb',
    'lib/login.rb',
    'lib/role.rb',
    'lib/userdivision.rb',
    'lib/userrole.rb',
  ]
  s.homepage    = 'https://rubygems.org/gems/pampa_workers'
  s.license     = 'MIT'
  s.add_runtime_dependency 'websocket', '~> 1.2.8', '>= 1.2.8'
  s.add_runtime_dependency 'json', '~> 1.8.1', '>= 1.8.1'
  s.add_runtime_dependency 'tiny_tds', '~> 1.0.5', '>= 1.0.5'
  s.add_runtime_dependency 'sequel', '~> 4.28.0', '>= 4.28.0'
  s.add_runtime_dependency 'simple_host_monitoring', '~> 1.1.8', '>= 1.1.8'
end