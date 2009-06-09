module Fiveruns::Manage::Targets::Rails::ActionController
  
  module RoutingError

    def self.included(base)
      Fiveruns::Manage.instrument base, InstanceMethods
    end

    module InstanceMethods
      def initialize_with_fiveruns_manage(*args, &block)
        Fiveruns::Manage.tally :routing_errs, nil, nil, nil do
          initialize_without_fiveruns_manage(*args, &block)
        end
      end
    end
    
  end

end