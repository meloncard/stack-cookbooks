include_recipe 'dependencies'

Chef::Log.info("Node deploy: #{node[:deploy].inspect}")

node[:deploy].each do |application, deploy|

  opsworks_deploy_user do
    deploy_data deploy
  end

end
