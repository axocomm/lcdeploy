require 'json'
require 'singleton'

require 'lcdeploy/resources'

module LCD
  class ResourceRunner
    include Singleton

    @@type_dispatch = {
      :create_directory     => CreateDirectory,
      :clone_repository     => CloneRepository,
      :build_docker_image   => BuildDockerImage,
      :run_docker_container => RunDockerContainer
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

def clone_repository(source, params = {})
  params.merge!(source: source)
  LCD::ResourceRunner.instance.dispatch :clone_repository, params
end

def build_docker_image(name, params = {})
  params.merge!(name: name)
  LCD::ResourceRunner.instance.dispatch :build_docker_image, params
end

def run_docker_container(name, params = {})
  params.merge!(name: name)
  LCD::ResourceRunner.instance.dispatch :run_docker_container, params
end
