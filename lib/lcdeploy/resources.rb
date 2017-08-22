module LCD
  class Resource
    def initialize(config = {})
      @config = config
    end

    def run!
      raise NotImplementedError, 'Resource class must implement run!'
    end

    def self.as_user(username, cmd)
      "sudo -u #{username} #{cmd}"
    end

    def to_s
      "#{name}#{@config.inspect}"
    end
  end

  class CreateDirectoryResource < Resource
    def run!(params = {})
      puts cmd_str(params)
    end

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
end
