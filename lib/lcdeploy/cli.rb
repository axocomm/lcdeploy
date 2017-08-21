require 'thor'

require 'lcdeploy/lcdfile'
require 'lcdeploy/util'

module LCD
  class CLI < Thor
    include LCD

    desc 'preview LCDFILE', 'Preview commands that will be run'
    def preview(filename = LCD::Util.default_lcdfile)
      lcdfile = LCD::LCDFile.new(filename)
    end

    desc 'deploy LCDFILE', 'Run a deploy'
    def deploy(filename = LCD::Util.default_lcdfile)
      lcdfile = LCD::LCDFile.new(filename)
      puts lcdfile.run!
    end
  end
end
