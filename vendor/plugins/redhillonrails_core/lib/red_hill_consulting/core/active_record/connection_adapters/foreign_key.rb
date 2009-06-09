module RedHillConsulting::Core::ActiveRecord::ConnectionAdapters
  class ForeignKey
    attr_reader :name, :table_name, :column_names, :references_table_name, :references_column_names, :on_update, :on_delete

    def initialize(name, table_name, column_names, references_table_name, references_column_names, on_update, on_delete)
      @name, @table_name, @column_names, @references_table_name, @references_column_names, @on_update, @on_delete = name, table_name, column_names, references_table_name, references_column_names, on_update, on_delete
    end

    def to_dump
      dump = "add_foreign_key"
      dump << " #{table_name.inspect}, [#{column_names.collect{ |name| name.inspect }.join(', ')}]"
      dump << ", #{references_table_name.inspect}, [#{references_column_names.collect{ |name| name.inspect }.join(', ')}]"
      dump << ", :on_update => :#{on_update}" if on_update
      dump << ", :on_delete => :#{on_delete}" if on_delete
      dump
    end
  end
end
