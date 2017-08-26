require 'erb'
require 'net/ssh'
require 'ostruct'
require 'tempfile'

class Net::SSH::Connection::Session
  class CommandFailed < StandardError
  end

  class CommandExecutionFailed < StandardError
  end

  def exec_sc!(cmd)
    stdout_data = ''
    stderr_data = ''
    exit_code = nil

    open_channel do |channel|
      channel.exec(cmd) do |_, success|
        unless success
          raise CommandExecutionFailed, "Command #{cmd} failed to execute"
        end

        channel.on_data do |_, data|
          stdout_data += data
        end

        channel.on_extended_data do |_, _, data|
          stderr_data += data
        end

        channel.on_request('exit-status') do |_, data|
          exit_code = data.read_long
        end
      end
    end

    loop

    {
      stdout: stdout_data,
      stderr: stderr_data,
      exit_code: exit_code
    }
  end
end

module LCD
  class Util
    @@TEMP_PREFIX = 'lcd-'

    def self.default_lcdfile
      File.join(Dir.pwd, 'lcdfile')
    end

    def self.create_temp_file!
      Tempfile.new @@TEMP_PREFIX
    end

    def self.render_template(content, params = {})
      template_binding = OpenStruct.new(params).instance_eval { binding }
      ERB.new(content).result(template_binding)
    end
  end
end
