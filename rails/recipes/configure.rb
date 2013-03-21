include_recipe "deploy"

node[:deploy].each do |application, deploy|
  deploy = node[:deploy][application]

  execute "restart Rails app #{application}" do
    cwd deploy[:current_path]
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

  # We're going to add a Beanstalk.yml config - HGH
  template "#{deploy[:deploy_to]}/shared/config/beanstalk.yml" do
    source "beanstalk.yml.erb"
    cookbook 'rails'
    mode "0660"
    group deploy[:group]
    owner deploy[:user]
    variables(:queue => { :ip => "127.0.0.1", :port => 11300 },
              :work => { :ip => "127.0.0.1", :port => 11301 }, 
              :environment => deploy[:rails_env])

    notifies :run, resources(:execute => "restart Rails app #{application}")

    only_if do
      File.exists?("#{deploy[:deploy_to]}") && File.exists?("#{deploy[:deploy_to]}/shared/config/")
    end
  end

  # We're going to add a Merchant.yml config - HGH
  template "#{deploy[:deploy_to]}/shared/config/merchant.yml" do
    source "merchant.yml.erb"
    cookbook 'rails'
    mode "0660"
    group deploy[:group]
    owner deploy[:user]
    variables(:merchant_api_key => 'xxx', :environment => deploy[:rails_env])
    
    notifies :run, resources(:execute => "restart Rails app #{application}")

    only_if do
      File.exists?("#{deploy[:deploy_to]}") && File.exists?("#{deploy[:deploy_to]}/shared/config/")
    end
  end

  # Then redis.yml - HGH
  template "#{deploy[:deploy_to]}/shared/config/redis.yml" do
    source "redis.yml.erb"
    cookbook 'rails'
    mode "0660"
    group deploy[:group]
    owner deploy[:user]
    variables(:session => { :ip => "127.0.0.1", :port => 6379 }, :environment => deploy[:rails_env])
    
    notifies :run, resources(:execute => "restart Rails app #{application}")

    only_if do
      File.exists?("#{deploy[:deploy_to]}") && File.exists?("#{deploy[:deploy_to]}/shared/config/")
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
