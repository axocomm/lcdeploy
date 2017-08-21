class Fixnum
  def to_base(to, from = 10)
    self.to_s.to_i(from).to_s(to)
  end
end

module LCD
  class Util
    def self.default_lcdfile
      File.join(Dir.pwd, 'lcdfile')
    end
  end
end
