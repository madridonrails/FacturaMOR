# NOTE: Run from RAILS_ROOT:
#   FIVERUNS_MANAGE_TARGET=rails rake test:plugins PLUGIN=fiveruns_manage

ENV['RAILS_ENV'] = 'test'
begin
  require 'config/environment'
  RAILS_ENV = ENV['RAILS_ENV'] unless defined?(RAILS_ENV)
rescue LoadError
  abort "Rails environment required for testing."
end

unless defined?(RAILS_ROOT)
  abort "Rails environment required for testing."
end

# Mock
module Fiveruns
  module Manage
    module Test
      class AdapterModel < ::ActiveRecord::Base
        set_table_name :adapter_models
        establish_connection :adapter  => 'sqlite3', :database => ':memory:'
      end
    end
  end
end

class RailsTargetTest < Test::Unit::TestCase
  
  context "Root" do    
    context "Mail" do
      wraps "ActionMailer::Base.receive"
      wraps "ActionMailer::Base#deliver!"
    end
  end

  context "Controller" do
    wraps "ActionController::Base#process"
    wraps "ActionController::Base#rescue_action"
    wraps "ActionController::Caching::Fragments#write_fragment"
    wraps "ActionController::Caching::Fragments#expire_fragment"
    wraps "ActionController::Caching::Pages::ClassMethods#cache_page"
    wraps "ActionController::Caching::Pages::ClassMethods#expire_page"
    wraps "ActionController::RoutingError#initialize"
  end
  
  context "View" do
    wraps "ActionView::Base#render_file"
    wraps "ActionView::Base#render"
    wraps "ActionView::Base#update_page"
  end
  
  context "Model" do    
    wraps "ActiveRecord::ActiveRecordError#initialize"
    wraps "ActiveRecord::Base.establish_connection"
    wraps "ActiveRecord::Base.retrieve_connection"
    wraps "ActiveRecord::Base.remove_connection"
    wraps "ActiveRecord::Base.find"
    wraps "ActiveRecord::Base.find_by_sql"
    wraps "ActiveRecord::Base.create"
    wraps "ActiveRecord::Base.update"
    wraps "ActiveRecord::Base.update_all"
    wraps "ActiveRecord::Base#update"
    wraps "ActiveRecord::Base#save"
    wraps "ActiveRecord::Base#save!"
    wraps "ActiveRecord::Base.destroy"
    wraps "ActiveRecord::Base.destroy_all"
    wraps "ActiveRecord::Base.delete"
    wraps "ActiveRecord::Base.delete_all"
    wraps "ActiveRecord::Base#destroy"
    context "Adapter" do
      should "instruments adapters" do
        assert_nothing_raised do
          Fiveruns::Manage::Test::AdapterModel.connection.create_table(:adapter_models) { |t| t.column :name, :string }
        end
        assert !Fiveruns::Manage.instrumented_adapters.blank?
        ActiveRecord::Base.active_connections.values.each do |connection|
          assert Fiveruns::Manage.instrumented_adapters.include?(connection.class)
          assert_wrapped connection.class.name, :instance, :begin_db_transaction
          assert_wrapped connection.class.name, :instance, :commit_db_transaction
          assert_wrapped connection.class.name, :instance, :rollback_db_transaction
          assert_wrapped connection.class.name, :instance, :initialize
          assert_wrapped connection.class.name, :instance, :disconnect!
        end
      end
    end
    context "Session" do
      wraps "CGI::Session#initialize"
      wraps "CGI::Session#close"
      wraps "CGI::Session#delete"
    end
  end
  
  context "Server" do
    context "Mongrel" do      
      wraps "Mongrel::HttpResponse#start"
      wraps "Mongrel::HttpResponse#write"
      wraps "Mongrel::HttpServer#process_client"
    end
  end

end
