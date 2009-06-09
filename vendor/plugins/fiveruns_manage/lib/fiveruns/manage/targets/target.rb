module Fiveruns::Manage::Targets
  
  class Target
    
    def self.inherited(klass)
      name = klass.to_s.demodulize.downcase.to_sym
      ::Fiveruns::Manage::Targets.supported[name] = klass
    end
    
    def self.allowed?
      false
    end
    
    attr_reader :configuration
        
    def name
      @name ||= ::Fiveruns::Manage::Targets.supported.invert[self.class]
    end
    
    def activate!
      unless @activated
        instrumentation_sets.each do |constant, instrumentation|
          begin
            constant.__send__(:include, instrumentation)
          rescue => e
            Fiveruns::Manage.log :debug, "Could not instrument #{constant} (#{e.message}, #{e.backtrace[0,4].join(' | ')})", true
          end
        end
        log_activation
        @activated = true
      end
    end
    
    def info
      { 
        :name => name,
        :started_at => Time.now.utc,
        :script => $0
      }
    end
    
    def logger
      Logger.new(STDERR)
    end
        
    def configure(&block)
      @configuration = configuration_class.new(&block)
    end
    
    def load_configuration!
      if configuration_file && File.file?(configuration_file)
        require configuration_file
      else
        @configuration = configuration_class.new
      end
    end
    
    #######
    private
    #######
    
    def configuration_file
      false
    end
    
    def configuration_class
      ::Fiveruns::Manage::Targets::Configuration
    end
    
    def log_activation
      Fiveruns::Manage.log :info, "Instrumented #{name}"
    end

    def instrumentation_path
      @instrumentation_path ||= File.dirname(__FILE__) << "/#{name}"
    end
    
    def instrumentation_files
      Dir[File.join(instrumentation_path, "/**/*.rb")]
    end
    
    def instrumentation_sets
      @instrumentation_sets ||= instrumentation_files.map do |filename|
        constant_path = filename[(instrumentation_path.size + 1)..-4]
        constant_name = path_to_constant_name(constant_path)
        
        require filename
        instrumentation = "#{self.class}::#{constant_name}".constantize
        
        if (constant = constant_name.constantize rescue nil)
          [constant, instrumentation]
        else
          if instrumentation.respond_to?(:complain?) && instrumentation.complain?
            Fiveruns::Manage.log :debug, "#{constant_name} not found; skipping instrumentation"
            Fiveruns::Manage.log :debug, "#{constant_name} is marked as needed for #{Fiveruns::Manage::Version.rails}", true
          else
            # Output a FiveRuns-development debugging message
            Fiveruns::Manage.log :debug, "#{constant_name} not found. #{instrumentation} not applied (not marked as needed for #{Fiveruns::Manage::Version.rails})", true
          end
          nil
        end
      end.compact
    end
    
    def path_to_constant_name(path)
      parts = path.split(File::SEPARATOR)
      parts.map(&:camelize).join('::').sub('Cgi', 'CGI')
    end
    
  end
  
end