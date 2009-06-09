require File.dirname(__FILE__) << "/test_helper"

target_name = if defined?(Fiveruns::Manage::Plugin)
  Fiveruns::Manage::Plugin.target.name rescue nil
elsif ENV['FIVERUNS_MANAGE_TARGET']
  ENV['FIVERUNS_MANAGE_TARGET']
else
  abort "Cannot determine instrumentation target to test;\nPlease set env variable FIVERUNS_MANAGE_TARGET (ie, 'rails')"
end

require File.dirname(__FILE__) << "/targets/#{target_name}"
