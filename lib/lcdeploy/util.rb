require 'erb'
require 'net/ssh'
require 'ostruct'
require 'tempfile'

class Fixnum
  def to_base(to, from = 10)
    self.to_s.to_i(from).to_s(to)
  end
end

class Net::SSH::Connection::Session
  class CommandFailed < StandardError
  end

  class CommandExecutionFailed < StandardError
  end

  def exec_sc!(cmd)
    stdout_data, stderr_data = '', ''
    exit_code, exit_signal = nil, nil
    self.open_channel do |channel|
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

        channel.on_request('exit-signal') do |_, data|
          exit_signal = data.read_long
        end
      end
    end

    self.loop

    {
      stdout: stdout_data,
      stderr: stderr_data,
      exit_code: exit_code,
      exit_signal: exit_signal
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
