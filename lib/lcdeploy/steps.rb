require 'net/ssh'
require 'singleton'

module LCD
  module Steps
    class Step
      def initialize(config = {})
        @config = config
      end

      def run!(params = {})
        cmd = cmd_str(params)
        puts "`#{cmd}`"
      end

      def cmd_str(params)
        raise NotImplementedError, 'Step class must implement cmd_str'
      end

      def self.as_user(username, cmd)
        "sudo -u #{username} #{cmd}"
      end

      def to_s
        "#{name}#{@config.inspect}"
      end
    end

    class RemoteStep < Step
      def run!(params = {})
        cmd = cmd_str(params)
        puts RemoteStep.ssh_exec(cmd, @config)
      end

      private
      def self.ssh_exec(cmd, config)
        user = config[:ssh_user] or raise "'ssh_user' must be configured"
        port = config[:ssh_port] || 22
        host = config[:ssh_host] or raise "'ssh_host' must be configured"

        extra_opts = { port: port }
        if password = config[:ssh_password]
          extra_opts.merge!(password: password)
        elsif ssh_key = config[:ssh_key]
          extra_opts.merge!(keys: [ssh_key])
        end

        Net::SSH.start(host, user, extra_opts) do |ssh|
          ssh.exec!(cmd)
        end
      end
    end

    class CreateDirectory < RemoteStep
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

    class CloneRepository < RemoteStep
      def cmd_str(params)
        source = params[:source] or raise "'source' parameter is required"
        target = params[:to] or raise "'target' parameter is required"
        user = params[:user]
        branch = params[:branch] || 'master'

        cmd = "git clone -b #{branch} #{source} #{target}"
        if user
          Step.as_user user, cmd
        else
          cmd
        end
      end
    end

    class BuildDockerImage < RemoteStep
      def cmd_str(params)
        name = params[:name] or raise "'name' parameter is required"
        path = params[:path] || '.'
        tag = params[:tag] || 'latest'

        "docker build -t #{name}:#{tag} #{path}"
      end
    end

    class RunDockerContainer < RemoteStep
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

  class StepRunner
    include Singleton

    @@type_dispatch = {
      :create_directory     => Steps::CreateDirectory,
      :clone_repository     => Steps::CloneRepository,
      :build_docker_image   => Steps::BuildDockerImage,
      :run_docker_container => Steps::RunDockerContainer
    }

    attr_accessor :config

    def dispatch(type, params = {})
      cls = @@type_dispatch[type] or raise "Unknown step type '#{type.to_s}'"
      step = cls.new(config)
      if $dry_run
        puts step.cmd_str(params)
      else
        step.run!(params)
      end
    end
  end
end
