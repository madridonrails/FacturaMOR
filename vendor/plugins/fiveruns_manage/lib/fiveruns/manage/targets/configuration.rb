module Fiveruns::Manage::Targets
  
  class Configuration

    attr_accessor :report_interval
    attr_writer :report_directory
    def initialize(&block)
      @report_interval = 20
      yield self if block_given?
    end

    def activate?
      true
    end

    def report_directory
      @report_directory ||= Dir.pwd
    end

    def report?
      true
    end
    
    def basename
      
    end

    def to_hash
      {
        :report_directory => report_directory,
        :report_interval => report_interval
      }
    end

  end
  
end