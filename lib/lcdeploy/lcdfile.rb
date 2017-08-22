module LCD
  class LCDFile
    def initialize(filename)
      raise "#{filename} does not exist" unless File.exist?(filename)
      @filename = filename
    end

    def preview
      File.open(@filename) do |fh|
        require 'lcdeploy/bootstrap'
        $dry_run = true
        eval fh.read
      end
    end

    def run!
      File.open(@filename) do |fh|
        require 'lcdeploy/bootstrap'
        eval fh.read
      end
    end
  end
end
