module Fiveruns::Manage::Targets
  
  class Rails < Target
    
    SUPPORT = {
      :obsolete => Fiveruns::Manage::Version.new(1, 2, 0),
      :min      => Fiveruns::Manage::Version.new(1, 2, 6),
      :max      => Fiveruns::Manage::Version.new(2, 2, 0)
    }
    
    def self.allowed?
      return false unless defined?(Rails)
      return false unless allow_script?
      if version < SUPPORT[:obsolete]
        Fiveruns::Manage.log :error, "Rails version (#{version}) is not supported (>= #{SUPPORT[:min]}); aborting"
        false
      elsif version >= SUPPORT[:obsolete] && version < SUPPORT[:min]
        Fiveruns::Manage.log :warn, "Rails version (#{version}) is not supported (>= #{SUPPORT[:min]}); instrumentation may not function correctly"
        true
      elsif version >= SUPPORT[:min] && version <= SUPPORT[:max]
        Fiveruns::Manage.log :debug, "Rails version (#{version}) is supported"          
        true
      else
        Fiveruns::Manage.log :warn, "Rails version (#{version}) is not currently supported (<= #{SUPPORT[:max]}); instrumentation may not function correctly"
        true
      end
    rescue
      # May occur in odd Rails environments; allow, but warn
      Fiveruns::Manage.log :warn, "Could not find Rails::VERSION, instrumentation may not function correctly" 
      true
    end
    
    def self.allow_script?
      if ENV.key?('LOAD_FIVERUNS_MANAGE')
        return ENV['LOAD_FIVERUNS_MANAGE']
      elsif %w(runner rake).include?(File.basename($0))
        false
      else
        true
      end
    end
    
    def logger
      RAILS_DEFAULT_LOGGER
    end
    
    def info
      super.merge(
        :env => RAILS_ENV,
        :version => self.class.version.to_s
      )
    end
    
    #######
    private
    #######
    
    def self.version
      Fiveruns::Manage::Version.new(::Rails::VERSION::MAJOR, ::Rails::VERSION::MINOR, ::Rails::VERSION::TINY)
    rescue
      nil
    end
    
    def log_activation
      Fiveruns::Manage.log :info, "Instrumented #{RAILS_ENV} environment."
    end
    
    def configuration_class
      Configuration
    end
    
    def configuration_file
      File.join(RAILS_ROOT, 'config/manage.rb')
    end
      
    # == Plugin Configuration
    #
    # Configure specific behavior of the plugin using a +configure+ block
    # in +config/manage.rb+
    #
    #   Fiveruns::Manage::Plugin.configure do |config|
    #     config.environments = %w(production)
    #     config.report_interval = 25
    #   end
    #
    # == Common Settings
    #
    # environments::
    #   Environments the plugin will instrument
    #   Default: production, development, test
    #
    # report_environments::
    #   Environments in which the plugin will report metrics
    #   Default: production, development
    #
    # report_directory::
    #   Directory to drop report (.yml) files
    #
    # report_interval::
    #   Interval between report updates, in seconds
    #   Default: 20 (Must be between 10 and 300)
    #
    class Configuration < ::Fiveruns::Manage::Targets::Configuration
      
      attr_reader :environments, :report_environments
      attr_writer :report_directory
      def initialize(&block)
        @environments = %w(production development staging test)
        @report_environments = %w(production staging development)
        super
      end
      
      def environments=(value)
        @environments = Array(value).map(&:to_s)
      end
      
      def report_environments=(value)
        @report_environments = Array(value).map(&:to_s)
      end
      
      def activate?
        @environments.include?(RAILS_ENV)
      end
      
      def report?
        @report_environments.include?(RAILS_ENV)
      end
      
      def report_directory
        @report_directory ||= File.join(RAILS_ROOT, 'log')
      end
      
      def to_hash
        super.merge(
          :environments => environments,
          :report_environments => report_environments
        )
      end
      
    end
    
  end
  
end
