require 'yaml'

# Explicitly require all files
$:.unshift(File.dirname(__FILE__) << "/..")

require 'fiveruns/manage'
require 'fiveruns/manage/version'
require 'fiveruns/manage/targets'
require 'fiveruns/manage/plugin'
require 'fiveruns/manage/reporter'

module Fiveruns
  module Manage
        
    class << self
      
      attr_accessor :context
      
      cattr_accessor :bytes_this_request
      cattr_accessor :current_model
      self.bytes_this_request = 0
      
      def instrument(target, *mods)
        mods.each do |mod|
          # Change target for 'ClassMethods' module
          real_target = mod.name.demodulize == 'ClassMethods' ? (class << target; self; end) : target
          real_target.__send__(:include, mod)
          # Find all the instrumentation hooks and chain them in
          mod.instance_methods.each do |meth|
            name = meth.to_s.sub('_with_fiveruns_manage', '')
            begin
              real_target.alias_method_chain(name, :fiveruns_manage)
            rescue
              Fiveruns::Manage.log :debug, "Could not instrument #{target} (#{meth})", true
            end
          end
        end
      end
      
      def log(level, text, require_debug = false)
        if !require_debug || ENV['FIVERUNS_DEBUG']
          text = "*Shhh* #{text}" if require_debug && ENV['FIVERUNS_DEBUG']
          log_with logger, level, text
        end
      end
      
      def log_with(use_logger, level, text)
        use_logger.send(level, "FiveRuns Manage (#{version_description}): #{text}")
      end
      
      def logger
        if ::Fiveruns::Manage::Targets.current?
          ::Fiveruns::Manage::Plugin.target.logger
        else
          Logger.new(STDERR)
        end
      end
      
      def instrumented_adapters
        @instrumented_adapters ||= []
      end
      
      def version_description
        @version_description ||= defined?(Version::DESCRIPTION) ? Version::DESCRIPTION : "v#{Version::STRING}"
      end
      
      def tracking_model(model_class)
        self.current_model = model_class.name
        block_result = yield model_class.name
        self.current_model = nil
        block_result
      end
            
      def controller_in_context
        context[1]
      end
      
      def action_in_context
        context[3]
      end
      
      def mutex
        @mutex ||= Mutex.new
      end
      
      def sync(&block)
        mutex.synchronize(&block)
      end
    
      def stopwatch
        start = Time.now
        yield
        Time.now - start
      end
    
      def namespace(container, context, properties)
        key = [container, context, properties]
        if (found = cache_map[key])
          namespace = cache[found]
        else
          namespace = Namespace.new(*key)
          cache << namespace
          cache_map[key] = cache.size - 1
        end
        
        # This namespace nil check is here to handle the very
        # rare situation where the reporter thread clears the
        # namespace cache in between this main thread's invocations
        # of cache_map[key] and cache[cache_map[key]].  When
        # this happens, the cache_map is populated and the cache
        # is empty, resulting in a nil namespace.  This workaround
        # passes a new, valid Namespace to the caller, but its
        # contents are never added to the cache.  The metrics
        # contained therein are lost in the ether.  :(
        if namespace.nil?
          namespace = Namespace.new(container, context, properties) 
        end
        namespace
      end
      
      def tally(metric, container=nil, context=context, properties=nil)
        metrics_in container, context, properties do |metrics|
          metrics[metric] += 1
        end
        yield if block_given?
      end
      
      def metrics_in(container=nil, context=nil, properties=nil)
        namespace = ::Fiveruns::Manage.namespace(container, context, properties)
        block_given? ? yield(namespace) : namespace
      end
      alias :metrics :metrics_in
      
      def cache_snapshot
        data = nil
        sync do
          data = cache
          clear
        end
        data
      end

      private

      def clear
        @cache = []
        @cache_map = {}
      end

      def cache
        @cache ||= []
      end

      def cache_map
        @cache_map ||= {}
      end
    end
    
    class Namespace
      
      attr_reader :name, :context
      attr_accessor :metrics, :properties
      
      delegate :[]=, :[], :to => :@metrics
      
      def initialize(name, context, properties)
        @name = name
        @context = context || []
        @properties = properties || []
        @metrics = Hash.new(0)
      end
      
      def to_yaml_type
        '!manage.fiveruns.com,2008/ns'
      end
      
    end
    
  end
end