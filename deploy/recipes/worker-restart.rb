#
# Cookbook Name:: deploy
# Recipe:: worker-restart

include_recipe 'deploy'

node[:deploy].each do |application, deploy|

  execute "restart worker" do
    command "monit restart worker"
    action :run
    
    only_if do 
      File.exists?("/etc/monit.d/worker.monitrc") # TODO: We can probably make this snazzier
    end
  end

end
