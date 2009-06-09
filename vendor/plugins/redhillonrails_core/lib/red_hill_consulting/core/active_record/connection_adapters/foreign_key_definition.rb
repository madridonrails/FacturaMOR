module RedHillConsulting::Core::ActiveRecord::ConnectionAdapters
  class ForeignKeyDefinition < Struct.new(:column_names, :references_table_name, :references_column_names, :on_update, :on_delete)
    ACTIONS = { :cascade => "CASCADE", :restrict => "RESTRICT", :set_null => "SET NULL" }.freeze

    def to_sql
      sql = "FOREIGN KEY (#{Array(column_names).join(", ")}) REFERENCES #{references_table_name} (#{Array(references_column_names).join(", ")})"
      sql << " ON UPDATE #{ACTIONS[on_update]}" if on_update
      sql << " ON DELETE #{ACTIONS[on_delete]}" if on_delete
      sql
    end
    alias :to_s :to_sql
  end
end
