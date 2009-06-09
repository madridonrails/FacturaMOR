module RedHillConsulting::Core::ActiveRecord::ConnectionAdapters
  module Column
    attr_accessor :unique_scope

    def unique
      !unique_scope.nil?
    end

    def required_on
      if null
        nil
      elsif default.nil?
        :save
      else
        :update
      end
    end
  end
end
