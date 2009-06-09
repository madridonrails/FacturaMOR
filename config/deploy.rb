set :application, "facturagem"
set :repository,  "https://larry.aspgems.com:8083/ayto-madrid/#{application}/trunk"
set :user, "#{application}"
ssh_options[:config] = false
set :use_sudo, false
set :keep_releases, 2
set :rails_env, "production"

set(:scm_username) { Capistrano::CLI.ui.ask("Type is your svn username: ") }
set(:scm_password){ Capistrano::CLI.password_prompt("Type your svn password for user #{scm_username}: ") }

set :deploy_via, :export
set :deploy_to, "/home/#{user}/app"

role :app, "hal.aspgems.com"
role :web, "hal.aspgems.com"
role :db,  "hal.aspgems.com", :primary => true

files=%w(database.yml mailer.rb facturagem.yml local_config.rb)
dirs=%w(config system/images)
after "deploy:update","deploy:symlink_config"
after "deploy:setup","deploy:create_dirs"

# Here comes the app config
after "deploy:symlink", "#{application}:symlink_tmp"
after "deploy:setup", "#{application}:create_shared_subdirs"

namespace :deploy do

  task :symlink_config, :roles => :app do
    files.each do |f|
      run "ln -nfs #{shared_path}/config/#{f} #{current_path}/config/#{f}"
    end
  end

  task :restart, :roles => :app do
    run "touch  #{current_path}/tmp/restart.txt"
  end

  task :create_dirs, :roles => :app do
    dirs.each do |d|
      run "mkdir -p #{shared_path}/#{d}"
    end
  end

  desc "Enables maintenance mode in the app"
  task :maintenance_on, :roles => :app do
    run "cp current/public/system/maintenance.html.disabled current/public/system/maintenance.html"
  end

  desc "Disables maintenance mode in the app"
  task :maintenance_off, :roles => :app do
    run "rm current/public/system/maintenance.html"
  end
end

# Here comes the application namespace for custom tasks

namespace application do

  desc "Create shared sub-directories in shared/tmp"
  task :create_shared_subdirs do
    dirs=%w(cache latex pids sessions sockets)
    run "mkdir -p #{deploy_to}/shared/tmp"
    dirs.each do |d|
      run "mkdir -p #{deploy_to}/shared/tmp/#{d}"
    end
  end

  desc "Symlink the tmp dir"
  task :symlink_tmp do
    run "rm -rf #{current_path}/tmp"
    run "ln -fs #{deploy_to}/shared/tmp #{current_path}/tmp"
    run "ln -fs #{deploy_to}/shared/pids #{current_path}/tmp/pids"
  end

end




