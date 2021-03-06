include_recipe "deploy"

node[:deploy].each do |application, deploy|
  deploy = node[:deploy][application]

  execute "restart Rails app #{application}" do
    cwd deploy[:current_path]
    group deploy[:group]
    user deploy[:user]
    command node[:opsworks][:rails_stack][:restart_command]
    action :nothing
  end

  node[:deploy][application][:database][:adapter] = OpsWorks::RailsConfiguration.determine_database_adapter(application, node[:deploy][application], "#{node[:deploy][application][:deploy_to]}/current", :force => node[:force_database_adapter_detection])

  template "#{deploy[:deploy_to]}/shared/config/database.yml" do
    source "database.yml.erb"
    cookbook 'rails'
    mode "0660"
    group deploy[:group]
    owner deploy[:user]
    variables(:database => deploy[:database], :environment => deploy[:rails_env])

    notifies :run, resources(:execute => "restart Rails app #{application}")

    only_if do
      File.exists?("#{deploy[:deploy_to]}") && File.exists?("#{deploy[:deploy_to]}/shared/config/")
    end
  end

  beanstalkd_server = node[:opsworks][:layers][:beanstalkd][:instances].keys.first rescue nil
  beanstalk_client = nil

  # Require a beanstalk server or config
  if beanstalkd_server
    beanstalk_client = node[:opsworks][:layers][:beanstalkd][:instances][beanstalkd_server][:private_dns_name]
  else
    beanstalk_client = deploy[:beanstalk][:client]
  end

  # We're going to add a Beanstalk.yml config - HGH
  template "#{deploy[:deploy_to]}/shared/config/beanstalk.yml" do
    source "beanstalk.yml.erb"
    cookbook 'rails'
    mode "0660"
    group deploy[:group]
    owner deploy[:user]
    variables(:client => beanstalk_client,
              :port => 11300,
              :environment => deploy[:rails_env])

    notifies :run, resources(:execute => "restart Rails app #{application}")

    only_if do
      File.exists?("#{deploy[:deploy_to]}") && File.exists?("#{deploy[:deploy_to]}/shared/config/")
    end
  end
  
  # We're going to add a Merchant.yml config - HGH
  if deploy['merchant']
    template "#{deploy[:deploy_to]}/shared/config/merchant.yml" do
      source "merchant.yml.erb"
      cookbook 'rails'
      mode "0660"
      group deploy[:group]
      owner deploy[:user]
      variables(:merchants => deploy['merchant'], :environment => deploy[:rails_env])
      
      notifies :run, resources(:execute => "restart Rails app #{application}")

      only_if do
        File.exists?("#{deploy[:deploy_to]}") && File.exists?("#{deploy[:deploy_to]}/shared/config/")
      end
    end
  end

  # We're going to add a merchants.yml config - note the `s`
  if deploy['merchants']
    template "#{deploy[:deploy_to]}/shared/config/merchants.yml" do
      source "merchants.yml.erb"
      cookbook 'rails'
      mode "0660"
      group deploy[:group]
      owner deploy[:user]
      variables(:merchants => deploy['merchants'], :environment => deploy[:rails_env])
      
      notifies :run, resources(:execute => "restart Rails app #{application}")

      only_if do
        File.exists?("#{deploy[:deploy_to]}") && File.exists?("#{deploy[:deploy_to]}/shared/config/")
      end
    end
  end

#   redis_server = node[:opsworks][:layers][:redis][:instances].keys.first rescue nil
#   redis_client = nil

#   # Require a redis server or config
#   if redis_server
#     redis_client = node[:opsworks][:layers][:redis][:instances][redis_server][:private_dns_name]
#   else
#     redis_client = deploy[:redis][:client]
#   end

  # Then redis.yml - HGH
  template "#{deploy[:deploy_to]}/shared/config/redis.yml" do
    source "redis.yml.erb"
    cookbook 'rails'
    mode "0660"
    group deploy[:group]
    owner deploy[:user]
    variables(:session => { :host => redis_client, :port => 6379 }, :environment => deploy[:rails_env])
    
    notifies :run, resources(:execute => "restart Rails app #{application}")

    only_if do
      File.exists?("#{deploy[:deploy_to]}") && File.exists?("#{deploy[:deploy_to]}/shared/config/")
    end
  end
  
  # Lets add public/private pem's, if supplied - HGH
  if deploy[:keys]
    directory "#{deploy[:deploy_to]}/shared/keys" do
      group deploy[:group]
      owner deploy[:user]
      mode "0770"
      action :create

      only_if do
        File.exists?("#{deploy[:deploy_to]}") && File.exists?("#{deploy[:deploy_to]}/shared")
      end
    end

    # This kind of stuff is going to have to be in the custom JSON - HGH
    file "#{deploy[:deploy_to]}/shared/keys/public.pem" do
      content deploy[:keys][:public]
      mode "0660"
      group deploy[:group]
      owner deploy[:user]

      notifies :run, resources(:execute => "restart Rails app #{application}")

      only_if do
        File.exists?("#{deploy[:deploy_to]}") && File.exists?("#{deploy[:deploy_to]}/shared/keys/")
      end
    end

    file "#{deploy[:deploy_to]}/shared/keys/private.pem" do
      content deploy[:keys][:private]
      mode "0660"
      group deploy[:group]
      owner deploy[:user]

      notifies :run, resources(:execute => "restart Rails app #{application}")

      only_if do
        File.exists?("#{deploy[:deploy_to]}") && File.exists?("#{deploy[:deploy_to]}/shared/keys/")
      end
    end
  end

  if deploy[:memcached] # This will be optional - HGH
    template "#{deploy[:deploy_to]}/shared/config/memcached.yml" do
      source "memcached.yml.erb"
      cookbook 'rails'
      mode "0660"
      group deploy[:group]
      owner deploy[:user]
      variables(:memcached => deploy[:memcached], :environment => deploy[:rails_env])

      notifies :run, resources(:execute => "restart Rails app #{application}")

      only_if do
        File.exists?("#{deploy[:deploy_to]}") && File.exists?("#{deploy[:deploy_to]}/shared/config/")
      end
    end
  end

end
