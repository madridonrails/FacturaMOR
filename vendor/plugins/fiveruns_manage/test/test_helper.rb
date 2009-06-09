require 'rubygems'
require 'test/unit'
require 'Shoulda'

class Test::Unit::TestCase
  
  def self.wraps(class_and_method)
    klass, type, meth = case class_and_method
    when /^(.+?)\.(.+?)$/
      [$1, :class, $2.to_sym]
    when /^(.+?)#(.+?)$/
      [$1, :instance, $2.to_sym]
    else
      raise ArgumentError, "Unknown class and method format: #{class_and_method}"
    end  
    should "wrap #{class_and_method}"  do
      assert_wrapped klass, type, meth
    end
  end
  
  def assert_wrapped(name, level, meth)
    constant = name.constantize rescue nil
    if constant
      corpus = method_corpus(constant, level)
      assert corpus.include?(meth.to_s), "Method entry not found"
      meth_format = format meth
      assert corpus.include?(meth_format % :with), "Could not find wrapper method `#{meth_format % :with}'"
      assert corpus.include?(meth_format % :without), "Could not find original method as `#{meth_format % :without}'"
    end
  end
  
  #######
  private
  #######
  
  def method_corpus(object, level)
    collections = if level == :class
      [:public_methods, :protected_methods, :private_methods]
    else
      [:public_instance_methods, :protected_instance_methods, :private_instance_methods]
    end
    collections.inject([]) do |list, collection|
      list.push(*object.__send__(collection))
    end
  end

  def format(meth)
    meth = meth.to_s
    feature = 'fiveruns_manage'
    if meth =~ /^(.*?)([?!=])$/
      meth = $1
      feature << $2
    end
    [meth, '%s', feature].join('_')
  end
  
end