require 'json'

require 'lcdeploy/steps'

def configure(config)
  if file = config[:from_file]
    File.open(file) do |fh|
      config = JSON.parse(fh.read, symbolize_names: true)
    end
  end

  LCD::StepRunner.instance.config = config
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

def put_file(target, params = {})
  params.merge!(target: target)
  LCD::StepRunner.instance.dispatch :put_file, params
end

def render_template(template, params = {})
  params.merge!(template: template)
  LCD::StepRunner.instance.dispatch :render_template, params
end
