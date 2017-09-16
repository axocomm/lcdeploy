require 'json'
require 'yaml'

require 'lcdeploy/config'
require 'lcdeploy/log'
require 'lcdeploy/steps'

class Hash
  def symbolize
    inject({}) do |acc, (k, v)|
      vv = if v.is_a?(Hash)
             v.symbolize
           else
             v
           end

      acc[k.to_sym] = vv
      acc
    end
  end
end

def configure(config)
  config = if config.key?(:from_json)
             File.open(config[:from_json]) do |fh|
               JSON.parse(fh.read, symbolize_names: true)
             end
           elsif config.key?(:from_yaml)
             YAML.load_file(config[:from_yaml]).symbolize
           else
             config
           end

  LCD::StepRunner.instance.config = LCD::Config.new(config)
end

def log(message, level = :info)
  LCD::Log.log message, level
end

def config
  LCD::StepRunner.instance.config || nil
end

def create_directory(target, params = {})
  params.merge!(target: target)
  LCD::StepRunner.instance.dispatch :create_directory, params
end

def clone_repository(source, params = {})
  params.merge!(source: source)
  LCD::StepRunner.instance.dispatch :clone_repository, params
end

def build_docker_image(name, params = {})
  params.merge!(name: name)
  LCD::StepRunner.instance.dispatch :build_docker_image, params
end

def run_docker_container(name, params = {})
  params.merge!(name: name)
  LCD::StepRunner.instance.dispatch :run_docker_container, params
end

def copy_file(source, params = {})
  params.merge!(source: source)
  LCD::StepRunner.instance.dispatch :copy_file, params
end

def render_template(template, params = {})
  params.merge!(template: template)
  LCD::StepRunner.instance.dispatch :render_template, params
end

def run_command(command, params = {})
  params.merge!(command: command)
  LCD::StepRunner.instance.dispatch :run_command, params
end

def run_local_command(command, params = {})
  params.merge!(command: command)
  LCD::StepRunner.instance.dispatch :run_local_command, params
end
