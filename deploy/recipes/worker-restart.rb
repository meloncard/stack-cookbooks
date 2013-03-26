#
# Cookbook Name:: deploy
# Recipe:: worker-restart

include_recipe 'deploy'

node[:deploy].each do |application, deploy|
  service 'monit' do
    supports :status => true, :restart => true, :reload => true
    action :restart
  end
end
