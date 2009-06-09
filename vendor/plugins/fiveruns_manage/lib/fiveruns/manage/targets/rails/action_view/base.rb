module Fiveruns::Manage::Targets::Rails::ActionView
  
  module Base
                    
    BASIC_TEMPLATE_PATH = File.join(RAILS_ROOT, 'app', 'views')           
  
    def self.included(base)
      Fiveruns::Manage.instrument base, InstanceMethods
    end
  
    def self.record(path, reset_bytes=false)
      if path
        result = nil
        time = Fiveruns::Manage.stopwatch { result = yield }
        bytes = result ? result.length : 0
        if reset_bytes
          Fiveruns::Manage.bytes_this_request = bytes
        else
          Fiveruns::Manage.bytes_this_request += bytes
        end
        normalized_path = self.normalize_path(path.to_s)
        Fiveruns::Manage.metrics_in :view, Fiveruns::Manage.context, [:name, normalized_path] do |metrics|
          metrics[:bytes] += bytes
          metrics[:proc_time] = time
          metrics[:reqs] += 1
        end
        result
      else
        yield # Just execute the method
      end
    end
          
    def self.normalize_path(path)
      return path unless path
      if path[0, BASIC_TEMPLATE_PATH.size] == BASIC_TEMPLATE_PATH
        path[(BASIC_TEMPLATE_PATH.size + 1)..-1]
      else
        if (components = path.split(File::SEPARATOR)).size > 2
          components[-2, 2].join(File::SEPARATOR)
        else
          components.join(File::SEPARATOR)
        end
      end
    end
  
    module InstanceMethods
      def render_file_with_fiveruns_manage(path, *args, &block)
        Fiveruns::Manage::Targets::Rails::ActionView::Base.record path, true do
          render_file_without_fiveruns_manage(path, *args, &block)
        end
      end
      def update_page_with_fiveruns_manage(*args, &block)
        path = block.to_s.split('/').last.split(':').first rescue ':update'
        Fiveruns::Manage::Targets::Rails::ActionView::Base.record path do
          update_page_without_fiveruns_manage(*args, &block)
        end
      end
      def render_with_fiveruns_manage(*args, &block)
        record = true
        options = args.first || {}
        path = case options
        when String
          # Pre-Rails 2.1, don't record this as it causes duplicate records 
          if Fiveruns::Manage::Version.rails < Fiveruns::Manage::Version.new(2,1,0)
            record = false
          else
            options
          end
        when :update
          block.to_s.split('/').last.split(':').first rescue ':update'
        when Hash
          if options[:file]
            options[:file].to_s
          elsif options[:partial]
            record = false
          elsif options[:inline]
            ':inline'
          elsif options[:text]
            ':text'
          end
        end
        path ||= '(unknown)'
      
        if record
          Fiveruns::Manage::Targets::Rails::ActionView::Base.record path do
            render_without_fiveruns_manage(*args, &block)
          end
        else
          render_without_fiveruns_manage(*args, &block)
        end
      end
            
      # This works for partial view path normalization in 2.1.
      # def fiveruns_normalize_partial_path(template_path)
      #   template = ::ActionView::PartialTemplate.new(self, template_path, false, {})
      #   full_extension = "." + template.filename.split('/').last.split('.', 2).last
      #   template.path.gsub(full_extension, '')
      # end
    end
    
  end

end