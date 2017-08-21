module LCD
  class LCDFile
    def initialize(filename)
      raise "#{filename} does not exist" unless File.exist?(filename)
      @filename = filename
    end

    def run!
      File.open(@filename) do |fh|
        eval fh.read
      end
    end
  end
end
