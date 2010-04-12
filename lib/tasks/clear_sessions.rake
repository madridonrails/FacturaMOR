namespace :facturamor do  
  desc "clear stale sessions"
  task :clear_sessions => :environment do |t|
    begin
      #CGI::Session::ActiveRecordStore::Session.destroy_all( ['updated_at <?', 1.hour.ago] )
      #ActiveRecord::Base.connection.execute "delete from sessions where utc_date() - updated_at > 86400"
      ActiveRecord::Base.connection.execute "delete from sessions where updated_at < DATE_SUB(CURDATE(), INTERVAL 1 DAY)"
    rescue
      puts $ERROR_INFO.inspect
    end
  end #task do
end #namespace

