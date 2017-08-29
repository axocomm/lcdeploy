module LCD
  class Log
    def self.log(message, level = :info)
      # TODO: Text color/bold
      prefix = case level
               when :warn
                 '^^^'
               when :error
                 '!!!'
               else
                '==='
               end
      puts "#{prefix} #{message}"
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
