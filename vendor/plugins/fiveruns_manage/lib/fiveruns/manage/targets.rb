require File.dirname(__FILE__) << "/targets/target"
require File.dirname(__FILE__) << "/targets/configuration"

module Fiveruns
  module Manage
    module Targets
      
      def self.supported
        @supported ||= {}
      end
      
      def self.current
        @current ||= if (t = supported.values.detect { |t| t.allowed? })
          t.new
        end
      end
      
      def self.current?
        @current
      end

    end
  end
end

Dir[File.dirname(__FILE__) << "/targets/*.rb"].each do |target_file|
  require target_file
end