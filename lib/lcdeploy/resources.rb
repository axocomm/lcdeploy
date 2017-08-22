module LCD
  class Resource
    def initialize(config = {})
      @config = config
    end

    def run!(params = {})
      puts cmd_str(params)
    end

    def cmd_str(params)
      raise NotImplementedError, 'Resource class must implement cmd_str'
    end

    def self.as_user(username, cmd)
      "sudo -u #{username} #{cmd}"
    end

    def to_s
      "#{name}#{@config.inspect}"
    end
  end

  class CreateDirectory < Resource
    def cmd_str(params)
      target = params[:target] or raise "'target' parameter is required"
      user = params[:user]
      group = params[:group]
      mode = params[:mode]

      cmd = []
      cmd << "mkdir #{target}"
      if user and group
        cmd << "chown #{user}:#{group} #{target}"
      elsif user
        cmd << "chown #{user} #{target}"
      elsif group
        cmd << "chown :#{group} #{target}"
      end

      if mode
        cmd << "chmod #{mode.to_s(10).to_i.to_s(8)} #{target}"
      end

      cmd.join(' && ')
    end
  end

  class CloneRepository < Resource
    def cmd_str(params)
      source = params[:source] or raise "'source' parameter is required"
      target = params[:to] or raise "'target' parameter is required"
      user = params[:user]
      branch = params[:branch] || 'master'

      cmd = "git clone -b #{branch} #{source} #{target}"
      if user
        Resource.as_user user, cmd
      else
        cmd
      end
    end
  end

  class BuildDockerImage < Resource
    def cmd_str(params)
      name = params[:name] or raise "'name' parameter is required"
      path = params[:path] || '.'
      tag = params[:tag] || 'latest'

      "docker build -t #{name}:#{tag} #{path}"
    end
  end

  class RunDockerContainer < Resource
    def cmd_str(params)
      image = params[:image] or raise "'image' parameter is required"
      name = params[:name] or raise "'name' parameter is required"
      ports = params[:ports]
      volumes = params[:volumes]

      cmd = []
      cmd << "docker run -d --name=#{name}"

      if ports
        cmd << ports.map do |pd|
          ps = pd.is_a?(Array) ? pd.join(':') : pd
          "-p #{ps}"
        end.join(' ')
      end

      if volumes
        cmd << volumes.map do |vd|
          "-v #{vd.join(':')}"
        end
      end

      cmd << image
      cmd.join(' ')
    end
  end
end
