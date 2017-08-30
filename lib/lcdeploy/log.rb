require 'colorize'

module LCD
  class Log
    def self.log(message, level = :info)
      prefix, color = case level
                      when :warn
                        ['^^^', :yellow]
                      when :error
                        ['!!!', :red]
                      else
                        ['===', :white]
                      end
      puts "#{prefix} #{message}".colorize(color: color, mode: :bold)
    end

    def self.info(message)
      log message, :info
    end

    def self.warn(message)
      log message, :warn
    end

    def self.error(message)
      log message, :error
    end
  end
end
