default[:opsworks][:rails_stack][:name] = "apache_passenger"
if node[:opsworks][:instance][:layers].include?('rails')
  Chef::Log.debug('Using rails stack')

  case node[:opsworks][:rails_stack][:name]
  when "apache_passenger"
    default[:opsworks][:rails_stack][:recipe] = "passenger_apache2::rails"
    default[:opsworks][:rails_stack][:needs_reload] = true
    default[:opsworks][:rails_stack][:service] = 'apache2'
    default[:opsworks][:rails_stack][:restart_command] = 'touch tmp/restart.txt'
  when "nginx_unicorn"
    default[:opsworks][:rails_stack][:recipe] = "unicorn::rails"
    default[:opsworks][:rails_stack][:needs_reload] = true
    default[:opsworks][:rails_stack][:service] = 'unicorn'
    default[:opsworks][:rails_stack][:restart_command] = '../../shared/scripts/unicorn clean-restart'
  else
    raise "Unknown stack: #{node[:opsworks][:rails_stack][:name].inspect}"
  end
elsif node[:opsworks][:instance][:layers].include?('worker')
  Chef::Log.debug('Using worker stack')
  default[:opsworks][:rails_stack][:recipe] = nil
  default[:opsworks][:rails_stack][:needs_reload] = true
  default[:opsworks][:rails_stack][:service] = nil
  default[:opsworks][:rails_stack][:restart_command] = 'touch tmp/restart.txt'
end