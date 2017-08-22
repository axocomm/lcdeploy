require 'json'

require 'lcdeploy/resources'

module LCD
  # This should actually take care of executing the commands generated
  # by the resources.
  #
  # TODO: I guess it is up to this to determine if commands are run
  # locally or over SSH. Perhaps it is best to have that returned by
  # the resources themselves instead, or turn the resources into their
  # own classes extending ShellCommand or something?
  class Bootstrap
    def initialize(config = {})
      @config = config || {}
      puts "!!! Initializing LCD::Bootstrap with #{@config}"
    end

    def run!(cmd, params = {})
      if params[:locally]
        puts "Running #{cmd} locally"
      else
        puts "Running #{cmd} remotely"
      end
    end
  end
end

def configure!(config)
  if file = config[:from_file]
    File.open(file) do |fh|
      $config = JSON.parse(fh.read, symbolize_names: true)
    end
  else
    $config = config
  end
end

def create_directory(name, params = {})
  cmd = LCD::Resources.create_directory(name, params)
  LCD::Bootstrap.new($config).run! cmd
end

def clone_repository(source, params = {})
  cmd = LCD::Resources.clone_repository(source, params)
  LCD::Bootstrap.new($config).run! cmd
end

def build_docker_image(name, params = {})
  cmd = LCD::Resources.build_docker_image(name, params)
  LCD::Bootstrap.new($config).run! cmd
end

def run_docker_container(name, params = {})
  cmd = LCD::Resources.run_docker_container(name, params)
  LCD::Bootstrap.new($config).run! cmd
end

def put_file(destination, params = {})
  cmd_params = $config.merge(params)
  cmd = LCD::Resources.put_file(destination, cmd_params)
  LCD::Bootstrap.new($config).run! cmd, locally: true
end
