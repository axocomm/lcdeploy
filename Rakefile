GEM_NAME = 'lcdeploy'

def latest_gem_file
  glob = "#{Dir.pwd}/*.gem"
  gems = Dir[glob]
  if gems.empty?
    nil
  else
    gems.sort.last
  end
end

desc "Build the #{GEM_NAME} gem"
task :build do
  sh "gem build #{GEM_NAME}.gemspec"
end

desc "Install the #{GEM_NAME} gem"
task :install, [:version] do |_, args|
  gem = if args.key?(:version)
          "#{GEM_NAME}-#{args[:version]}.gem"
        else
          latest_gem_file
        end

  raise 'No installable gems found' if gem.nil?

  sh "gem install #{gem}"
end

task :default => [:build, :install]
