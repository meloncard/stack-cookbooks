define :opsworks_rails do
  deploy = params[:deploy_data]
  application = params[:app]

  include_recipe node[:opsworks][:rails_stack][:recipe]

  # write out memcached.yml
  template "#{deploy[:deploy_to]}/shared/config/memcached.yml" do
    cookbook "rails"
    source "memcached.yml.erb"
    mode "0660"
    owner deploy[:user]
    group deploy[:group]
    variables(:memcached => (deploy[:memcached] || {}), :environment => deploy[:rails_env])
  end

  execute "symlinking subdir mount if necessary" do
    command "rm -f /var/www/#{deploy[:mounted_at]}; ln -s #{deploy[:deploy_to]}/current/public /var/www/#{deploy[:mounted_at]}"
    action :run
    only_if do
      deploy[:mounted_at] && File.exists?("/var/www")
    end
  end

  Chef::Log.info("Symlinking #{release_path}/public/assets to #{new_resource.deploy_to}/shared/assets")
   
  link "#{release_path}/public/assets" do
    to "#{new_resource.deploy_to}/shared/assets"
  end
   
  rails_env = new_resource.environment["RAILS_ENV"]
  Chef::Log.info("Precompiling assets for RAILS_ENV=#{rails_env}...")
   
  execute "rake assets:precompile" do
    cwd release_path
    command "bundle exec rake assets:precompile"
    environment "RAILS_ENV" => rails_env
  end
end 
