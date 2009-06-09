module Fiveruns::Manage::Targets::Rails::ActiveRecord
  
  module Base
          
    # 1. Store the current model name so error metrics during execution can refer to it
    # 2. Execute the operation, time it, and store the result
    # 3. Add metrics relating to this event to a Namespace with the current model name
    # 4. Return the operation result so the enclosing method can return it
    def self.record(event, model, &operation)
      result = nil
      Fiveruns::Manage.tracking_model model do |name|
        time = Fiveruns::Manage.stopwatch { result = yield }
        Fiveruns::Manage.metrics_in :model, Fiveruns::Manage.context, [:name, name] do |metrics|
          metrics[event.to_s.pluralize.to_sym] += 1
          metrics["#{event}_time".to_sym] += time
          # TODO: metrics["#{event}_errors".to_sym]
        end
      end
      result
    end
  
    def self.record_connection(model)
      result = yield
      if model.respond_to?(:connection_pool)
        record_connection_with_pooling(model)
      else
        record_connection_without_pooling(model)
      end
      result
    end
    
    def self.record_connection_without_pooling(model)
      Fiveruns::Manage.metrics_in nil, nil, nil do |metrics|
        metrics[:active_conns] = model.active_connections.size
      end
      connections = model.active_connections
      adapter     = connections[connections.keys.first].class
      if adapter != NilClass && !Fiveruns::Manage.instrumented_adapters.include?(adapter)
        instrument_adapter(adapter)
      end
    end
    
    def self.record_connection_with_pooling(model)
      pool = model.connection_pool
      checked_out = pool.instance_eval { @checked_out }
      Fiveruns::Manage.metrics_in nil, nil, nil do |metrics|
        metrics[:active_conns] = checked_out.size
      end
      adapter     = checked_out.first.class
      if adapter != NilClass && !Fiveruns::Manage.instrumented_adapters.include?(adapter)
        instrument_adapter(adapter)
      end
    end
  
    def self.instrument_adapter(adapter)
      adapter.send(:include, AdapterMethods)
      Fiveruns::Manage.instrumented_adapters << adapter
    end
    
    def self.included(base)
      Fiveruns::Manage.instrument base, InstanceMethods, ClassMethods
    end
  
    module AdapterMethods
    
      def self.included(base)
        Fiveruns::Manage.instrument base, InstanceMethods
      end
    
      module InstanceMethods
      
        def begin_db_transaction_with_fiveruns_manage(*args, &block)
          Fiveruns::Manage.tally :tx_starts, nil, nil, nil do
            begin_db_transaction_without_fiveruns_manage(*args, &block)
          end
        end
      
        def commit_db_transaction_with_fiveruns_manage(*args, &block)
          Fiveruns::Manage.tally :tx_commits, nil, nil, nil do
            commit_db_transaction_without_fiveruns_manage(*args, &block)
          end
        end
      
        def rollback_db_transaction_with_fiveruns_manage(*args, &block)
          Fiveruns::Manage.tally :tx_aborts, nil, nil, nil do
            rollback_db_transaction_without_fiveruns_manage(*args, &block)
          end
        end
      
        def initialize_with_fiveruns_manage(*args, &block)
          Fiveruns::Manage.tally :creates, nil, nil, nil do
            initialize_without_fiveruns_manage(*args, &block)
          end
        end
      
        def disconnect_with_fiveruns_manage!(*args, &block)
          Fiveruns::Manage.tally :disconnects, nil, nil, nil do
            disconnect_without_fiveruns_manage!(*args, &block)
          end
        end

      end
    end
  
    module ClassMethods
      def establish_connection_with_fiveruns_manage(*args, &block)
        Fiveruns::Manage::Targets::Rails::ActiveRecord::Base.record_connection self do
          establish_connection_without_fiveruns_manage(*args, &block)
        end
      end
      def retrieve_connection_with_fiveruns_manage(*args, &block)
        Fiveruns::Manage::Targets::Rails::ActiveRecord::Base.record_connection self do
          retrieve_connection_without_fiveruns_manage(*args, &block)
        end
      end
      def remove_connection_with_fiveruns_manage(*args, &block)
        result = remove_connection_without_fiveruns_manage(*args, &block)
        Fiveruns::Manage.metrics_in nil, nil, nil do |metrics|
          metrics[:removes] += 1
          metrics[:active_conns] = self.active_connections.size
        end
        result
      end
      #
      # FINDS
      #
      def find_with_fiveruns_manage(*args, &block)
        Fiveruns::Manage::Targets::Rails::ActiveRecord::Base.record :find,  self do
          find_without_fiveruns_manage(*args, &block)
        end
      end
      def find_by_sql_with_fiveruns_manage(*args, &block)
        Fiveruns::Manage::Targets::Rails::ActiveRecord::Base.record :find, self do
          find_by_sql_without_fiveruns_manage(*args, &block)
        end
      end
      #
      # CREATE
      #
      def create_with_fiveruns_manage(*args, &block)
        Fiveruns::Manage::Targets::Rails::ActiveRecord::Base.record :create, self do
          create_without_fiveruns_manage(*args, &block)
        end
      end
      #
      # UPDATES
      #
      def update_with_fiveruns_manage(*args, &block)
        Fiveruns::Manage::Targets::Rails::ActiveRecord::Base.record :update, self do
          update_without_fiveruns_manage(*args, &block)
        end
      end
      def update_all_with_fiveruns_manage(*args, &block)
        Fiveruns::Manage::Targets::Rails::ActiveRecord::Base.record :update, self do
          update_all_without_fiveruns_manage(*args, &block)
        end
      end
      #
      # DELETES
      #
      def destroy_with_fiveruns_manage(*args, &block)
        Fiveruns::Manage::Targets::Rails::ActiveRecord::Base.record :delete, self do
          destroy_without_fiveruns_manage(*args, &block)
        end
      end
      def destroy_all_with_fiveruns_manage(*args, &block)
        Fiveruns::Manage::Targets::Rails::ActiveRecord::Base.record :delete, self do
          destroy_all_without_fiveruns_manage(*args, &block)
        end
      end
      def delete_with_fiveruns_manage(*args, &block)
        Fiveruns::Manage::Targets::Rails::ActiveRecord::Base.record :delete, self do
          delete_without_fiveruns_manage(*args, &block)
        end
      end
      def delete_all_with_fiveruns_manage(*args, &block)
        Fiveruns::Manage::Targets::Rails::ActiveRecord::Base.record :delete, self do
          delete_all_without_fiveruns_manage(*args, &block)
        end
      end
    end
  
    module InstanceMethods
      #
      # UPDATES
      #
      def update_with_fiveruns_manage(*args, &block)
        Fiveruns::Manage::Targets::Rails::ActiveRecord::Base.record :update, self.class do
          update_without_fiveruns_manage(*args, &block)
        end
      end
      def save_with_fiveruns_manage(*args, &block)
        Fiveruns::Manage::Targets::Rails::ActiveRecord::Base.record :update, self.class do
          save_without_fiveruns_manage(*args, &block)
        end
      end
      def save_with_fiveruns_manage!(*args, &block)
        Fiveruns::Manage::Targets::Rails::ActiveRecord::Base.record :update, self.class do
          save_without_fiveruns_manage!(*args, &block)
        end
      end
      #
      # DELETES
      #
      def destroy_with_fiveruns_manage(*args, &block)
        Fiveruns::Manage::Targets::Rails::ActiveRecord::Base.record :delete, self.class do
          destroy_without_fiveruns_manage(*args, &block)
        end
      end
    end
    
  end

end