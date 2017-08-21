require 'lcdeploy/resources'

def create_directory(name, params = {})
  cmd = LCD::Resources.create_directory(name, params)
  if @dry_run
    puts cmd
  end
end

def clone_repository(source, params = {})
  cmd = LCD::Resources.clone_repository(source, params)
  if @dry_run
    puts cmd
  end
end

def build_docker_image(name, params = {})
  cmd = LCD::Resources.build_docker_image(name, params)
  if @dry_run
    puts cmd
  end
end

def run_docker_container(name, params = {})
  cmd = LCD::Resources.run_docker_container(name, params)
  if @dry_run
    puts cmd
  end
end
