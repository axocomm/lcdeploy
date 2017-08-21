require 'lcdeploy/resources'

def create_directory(name, params = {})
  puts LCD::Resources.create_directory(name, params)
end

def clone_repository(source, params = {})
  puts LCD::Resources.clone_repository(source, params)
end

def build_docker_image(name, params = {})
  puts LCD::Resources.build_docker_image(name, params)
end

def run_docker_container(name, params = {})
  puts LCD::Resources.run_docker_container(name, params)
end
