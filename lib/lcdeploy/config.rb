module LCD
  class Config
    def initialize(config)
      @config = config
    end

    def [](key)
      @config[key] || nil
    end

    def method_missing(method, *args)
      @config[method.to_sym] || nil
    end
  end
end
