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
    @@ssh_base_config = {
      port: 22,
      host: 'localhost'
    }

    private
    def self.run(cmd, params = {})
      title = params[:title] || cmd

      if cmd.nil?
        puts "!!! Skipping #{title}"
        return
      end

      if params[:ssh]
        ssh_config = @@ssh_base_config.merge(params[:ssh_config] || {})
        cmd = "ssh -p#{ssh_config[:port]} #{ssh_config[:host]} #{cmd}"
      end

      if $dry_run or params[:dry_run]
        puts cmd
        return
      end

      puts "Actually running #{cmd}"
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
