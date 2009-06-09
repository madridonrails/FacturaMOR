module Fiveruns::Manage::Targets::Rails::ActionView

  # For Rails ~ >= 2.2.0, when PartialTemplate was refactored into the RenderablePartial mixin
  module RenderablePartial

    def self.included(base)
      Fiveruns::Manage.instrument base, InstanceMethods
    end
    
    def self.complain?
      Fiveruns::Manage::Version.rails >= Fiveruns::Manage::Version.new(2, 2, 0)
    end

    module InstanceMethods
      def render_partial_with_fiveruns_manage(*args, &block)
        Fiveruns::Manage::Targets::Rails::ActionView::Base.record path_without_format_and_extension do
          render_partial_without_fiveruns_manage(*args, &block)
        end
      end
    end
    
  end

end
