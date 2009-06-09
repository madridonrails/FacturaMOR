require 'thread'
Thread.abort_on_exception = true

module Fiveruns
  
  module Manage
    
    class Reporter

      def initialize
        @config = ::Fiveruns::Manage::Plugin.target.configuration
        create_directory if start?
      end

      def start
        return false if !start?
        unless alive?
          setup_file_removal!
          Fiveruns::Manage.log :debug, "Reporting metrics in #{@config.report_interval}s intervals to #{File.basename(report_filename)}"
          @thread = Thread.new do
            write_passenger
            write_info
            start_report
            loop do
              sleep @config.report_interval
              report
            end
          end
        end
      end
      
      def alive?
        @thread && @thread.alive?
      end
      
      def start?
        @config.report?
      end
      
      def cleanup
        FileUtils.rm report_filename rescue nil
        FileUtils.rm info_filename rescue nil
      end
      
      #######
      private
      #######
      
      def report
        if @config.report?
          begin
            data = ::Fiveruns::Manage.cache_snapshot

            File.open(report_filename, 'a') do |f|
              ::Fiveruns::Manage.sync do
                f.write(
                  { :time => Time.now.utc,
                    :data => data
                  }.to_yaml
                )
              end
              f.chmod 0666
            end
          rescue Exception => e
            ::Fiveruns::Manage.log :warn, "Could not write to #{report_filename}"
          end
        end
      end

      def setup_file_removal!
        at_exit do
          if retain_files?
            report 
          else
            cleanup
          end
        end
      end
      
      def retain_files?
        false # For future use
      end
      
      def report_filename
        @report_filename ||= File.join(@config.report_directory, 'fiveruns', "fiveruns-manage.#{File.basename($0)[0,10]}.#{Process.pid}.yml")
      end

      def info_filename
        @info_filename ||= File.join(@config.report_directory, 'fiveruns', "info.yml")
      end
      
      def passenger_filename
        @passenger_filename ||= File.join(@config.report_directory, 'fiveruns', "passenger.yml")
      end

      def write_info
        if @config.report?
          FileUtils.rm_f info_filename
          File.open(info_filename, 'w') do |f|        
            f.puts ::Fiveruns::Manage::Plugin::Info.new.to_yaml
          end
        end
      end

      def write_passenger
        if @config.report? && passenger? && !File.exist?(passenger_filename)
          File.open(passenger_filename, 'w') do |f|
            f.puts %(This file tells the FiveRuns Client that this Rails app is being\nserved by Phusion Passenger.  Do not remove it.).to_yaml
          end
        elsif File.exist?(passenger_filename) && !passenger?
          FileUtils.rm_f passenger_filename
        end
      end

      def passenger?
        !!(defined? Passenger::Application)
      end

      def start_report
        if @config.report?
          File.open(report_filename, 'w') do |f|
            f.puts "# Started #{Time.now.utc.xmlschema}"
          end
        end
      end
      
      def create_directory
        path = File.dirname(report_filename)
        return if File.exists?(path)
        FileUtils.mkdir_p path
        FileUtils.chmod 0777, path
      end

    end
  end
end
