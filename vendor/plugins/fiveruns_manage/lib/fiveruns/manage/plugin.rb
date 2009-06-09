require 'ostruct'

module Fiveruns
  
  module Manage
    
    module Plugin
            
      class << self
        
        attr_reader :info

        def config(&block)
          target.configure(&block)
        end
        alias :configure :config
        
        def target
          @target ||= begin
            target = Fiveruns::Manage::Targets.current
            if target
              target.load_configuration!
            end
            target
          end
        end
        
        def reporter
          @reporter = if !defined?(@reporter) || !@reporter.alive?
            reporter = Fiveruns::Manage::Reporter.new
            reporter.start
            reporter
          else
            @reporter
          end
        end
              
        def start
          return unless target
          if target.configuration.activate?
            target.activate!
            if target.configuration.report?
              reporter.start
            else
              Fiveruns::Manage.log :debug, "Not reporting metrics."
            end
          else
            Fiveruns::Manage.log :error, "Not instrumenting #{target.name}"
          end
        end
        
      end
      
      class Info

        def initialize
          @ruby = {
            :pid => Process.pid,
            :version => RUBY_VERSION,
            :platform => RUBY_PLATFORM
          }
          @version = Fiveruns::Manage::Version::STRING
          @target = Fiveruns::Manage::Plugin.target.info
        end
        
        def to_yaml_type
          '!manage.fiveruns.com,2008/info'
        end

      end
      
    end
    
  end
  
end