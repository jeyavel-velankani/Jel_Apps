namespace :setup do

  desc "upload protected config files to shared_path"
  task :upload_config do
    on roles(:all) do #|host|
      upload! 'config/database.yml', "#{shared_path}/config/database.yml"
      upload! 'config/secrets.yml', "#{shared_path}/config/secrets.yml"
    end
  end

end
