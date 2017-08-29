Gem::Specification.new do |s|
  s.name        = 'lcdeploy'
  s.version     = '0.2'
  s.executables << 'lcd'
  s.date        = '2017-08-21'
  s.summary     = 'Drama-free deploys'
  s.description = 'Simple specification of basic deploy steps'
  s.authors     = %w(axocomm)
  s.email       = 'axocomm@gmail.com'
  s.files       = ['lib/lcdeploy/bootstrap.rb',
                   'lib/lcdeploy/cli.rb',
                   'lib/lcdeploy/config.rb',
                   'lib/lcdeploy/log.rb',
                   'lib/lcdeploy/util.rb',
                   'lib/lcdeploy/lcdfile.rb',
                   'lib/lcdeploy/steps.rb']
  s.license     = 'GPL-3.0'

  s.add_dependency 'thor', '~> 0.20'
  s.add_dependency 'net-ssh', '~> 3.1'
  s.add_dependency 'net-scp', '~> 1.2'
end
