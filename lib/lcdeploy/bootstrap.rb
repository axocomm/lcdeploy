require 'lcdeploy/resources'

module LCD
  class Bootstrap
    private
    def self.run(cmd)
      if $dry_run
        puts cmd
      else
        puts "Actually running #{cmd}"
      end
    end
  end
end

def create_directory(name, params = {})
  cmd = LCD::Resources.create_directory(name, params)
  LCD::Bootstrap.run cmd
end

def clone_repository(source, params = {})
  cmd = LCD::Resources.clone_repository(source, params)
  LCD::Bootstrap.run cmd
end

def build_docker_image(name, params = {})
  cmd = LCD::Resources.build_docker_image(name, params)
  LCD::Bootstrap.run cmd
end

def run_docker_container(name, params = {})
  cmd = LCD::Resources.run_docker_container(name, params)
  LCD::Bootstrap.run cmd
end
