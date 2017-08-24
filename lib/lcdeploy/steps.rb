require 'net/ssh'
require 'net/scp'
require 'singleton'

require 'lcdeploy/util'

module LCD
  module Steps
    class Step
      def initialize(config = {})
        @config = config
      end

      def run!(params = {})
        cmd = cmd_str(params)
        if should_run?(params)
          puts "`#{cmd}`"
        else
          puts "Skipping `#{cmd}`"
        end
      end

      def cmd_str(params)
        raise NotImplementedError, 'Step class must implement cmd_str'
      end

      def preview(params)
        "L: #{cmd_str(params)}"
      end

      # TODO: a more robust approach, e.g. what happens when the file
      # exists but the permissions are wrong? Or content doesn't match?
      #
      # Maybe a collection of checks to run per-step instead of just
      # a predicate
      def should_run?(params)
        true
      end

      def self.as_user(username, cmd)
        "sudo -u #{username} #{cmd}"
      end

      private
      def ssh_exec(cmd)
        user = @config[:ssh_user] or raise "'ssh_user' must be configured"
        port = @config[:ssh_port] || 22
        host = @config[:ssh_host] or raise "'ssh_host' must be configured"

        extra_opts = { port: port }
        if password = @config[:ssh_password]
          extra_opts.merge!(password: password)
        elsif ssh_key = @config[:ssh_key]
          extra_opts.merge!(keys: [ssh_key])
        end

        Net::SSH.start(host, user, extra_opts) do |ssh|
          ssh.exec_sc!(cmd)
        end
      end

      def upload_file(params)
        user = @config[:ssh_user] or raise "'ssh_user' must be configured"
        port = @config[:ssh_port] || 22
        host = @config[:ssh_host] or raise "'ssh_host' must be configured"

        extra_opts = { port: port }
        if password = @config[:ssh_password]
          extra_opts.merge!(password: password)
        elsif ssh_key = @config[:ssh_key]
          extra_opts.merge!(keys: [ssh_key])
        end

        source = params[:source] or raise "'source' is required"
        target = params[:target] or raise "'target' is required"

        Net::SCP.upload!(host, user, source, target, ssh: extra_opts)
      end

      def to_s
        "#{name}#{@config.inspect}"
      end
    end

    class RemoteStep < Step
      def run!(params = {})
        cmd = cmd_str(params)
        if should_run?(params)
          puts ssh_exec(cmd)
        else
          puts "Skipping remote `#{cmd}`"
        end
      end

      def preview(params)
        "R: #{cmd_str(params)}"
      end
    end

    # TODO: consider another child class for steps that run commands and
    # steps that do not necessarily depend on a single command.
    class CopyFile < Step
      def run!(params = {})
        if should_run?(params)
          upload_file(params) # TODO: set permissions of remote file
        else
          puts "Skipping upload of #{params[:target]}"
        end
      end

      def preview(params)
        "L: scp -P#{@config[:ssh_port]} #{params[:source]} #{@config[:ssh_user]}@#{@config[:ssh_host]}:#{params[:target]}"
      end

      # TODO: check file content (MD5?)
      def should_run?(params)
        result = ssh_exec("test -f #{params[:target]}")
        result[:exit_code] == 1
      end
    end

    # Render a template locally and SCP to host.
    class RenderTemplate < Step
      def run!(params = {})
        template = params[:template] or raise "'template' parameter is required"
        target = params[:target] or raise "'target' parameter is required"
        template_params = params[:params] || {}

        # TODO: remote file user/group/mode
        # user = params[:user]
        # group = params[:group]
        # mode = params[:mode] || 0644

        raise "'#{template}' does not exist" unless File.exist?(template)

        File.open(template) do |fh|
          temp = LCD::Util.create_temp_file!
          rendered = LCD::Util.render_template(fh.read, template_params)
          File.open(temp, 'w') do |tfh|
            tfh.write(rendered)
            tfh.close

            upload_file source: temp.path, target: target
          end
        end
      end

      def preview(params)
        target = params[:target]
        cmd = [
          "L: erb #{params[:template]} > tmpfile",
          "L: scp -P#{@config[:ssh_port]} #{@config[:ssh_user]}@#{@config[:ssh_host]}:#{target}"
        ]

        user = params[:user]
        group = params[:group]
        if user and group
          cmd << "R: chown #{user}:#{group} #{target}"
        elsif user
          cmd << "R: chown #{user} #{target}"
        elsif group
          cmd << "R: chgrp #{group} #{target}"
        end

        if mode = params[:mode]
          cmd << "R: chmod #{mode.to_s(10).to_i.to_s(8)} #{target}"
        end

        cmd.join("\n")
      end

      # TODO: as above, check file MD5
      def should_run?(params)
        result = ssh_exec("test -f #{params[:target]}")
        result[:exit_code] == 1
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
          cmd << "chgrp #{group} #{target}"
        end

        if mode
          cmd << "chmod #{mode.to_s(10).to_i.to_s(8)} #{target}"
        end

        cmd.join(' && ')
      end

      def should_run?(params)
        result = ssh_exec("test -d #{params[:target]}")
        result[:exit_code] == 1
      end
    end

    class CloneRepository < RemoteStep
      def cmd_str(params)
        source = params[:source] or raise "'source' parameter is required"
        target = params[:target] or raise "'target' parameter is required"
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
        path = params[:path] or raise "'path' parameter is required"
        tag = params[:tag] || 'latest'

        "docker build -t #{name}:#{tag} #{path}"
      end

      def should_run?(params)
        cmd = "docker images | grep -qs #{params[:name]}"
        result = ssh_exec(cmd)
        params[:rebuild] || result[:exit_code] == 1
      end
    end

    class RunDockerContainer < RemoteStep
      def cmd_str(params)
        image = params[:image] or raise "'image' parameter is required"
        name = params[:name] or raise "'name' parameter is required"
        tag = params[:tag] || 'latest'
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

        cmd << "#{image}:#{tag}"
        cmd.join(' ')
      end

      def should_run?(params)
        cmd = "docker ps | grep -qs #{params[:name]}"
        result = ssh_exec(cmd)
        result[:exit_code] == 1
      end
    end

    class RunCommand < RemoteStep
      def cmd_str(params)
        cmd = params[:command]
        user = params[:user]
        cwd = params[:cwd]

        if cwd
          cmd = "cd #{cwd} && #{cmd}"
        end

        if user
          cmd = "#{as_user(user)} #{cmd}"
        end

        cmd
      end
    end
  end

  class StepRunner
    include Singleton

    @@type_dispatch = {
      :create_directory     => Steps::CreateDirectory,
      :clone_repository     => Steps::CloneRepository,
      :build_docker_image   => Steps::BuildDockerImage,
      :run_docker_container => Steps::RunDockerContainer,
      :copy_file            => Steps::CopyFile,
      :render_template      => Steps::RenderTemplate,
      :run_command          => Steps::RunCommand
    }

    attr_accessor :config

    def dispatch(type, params = {})
      cls = @@type_dispatch[type] or raise "Unknown step type '#{type.to_s}'"
      step = cls.new(config)
      if $dry_run
        puts step.preview(params)
      else
        step.run!(params)
      end
    end
  end
end
