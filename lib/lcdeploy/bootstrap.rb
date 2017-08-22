require 'json'
require 'singleton'

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

  class ResourceRunner
    include Singleton

    @@type_dispatch = {
      :create_directory => CreateDirectoryResource
    }

    attr_accessor :config

    def dispatch(type, params = {})
      cls = @@type_dispatch[type] or raise "Unknown resource type '#{type.to_s}'"
      resource = cls.new(config)
      resource.run!(params)
    end
  end
end

def configure(config)
  if file = config[:from_file]
    File.open(file) do |fh|
      config = JSON.parse(fh.read, symbolize_names: true)
    end
  end

  LCD::ResourceRunner.instance.config = config
end

def create_directory(target, params = {})
  params.merge!(target: target)
  LCD::ResourceRunner.instance.dispatch :create_directory, params
end
