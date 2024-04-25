#
# Cookbook:: myapache
# Recipe:: server
#
# Copyright:: 2024, The Authors, All Rights Reserved.
package 'apache2'

file '/var/www/html/index.html' do
    content '<h1>Hello World!, First Chef Project</h1>'
end

service 'apache2' do
    action [:enable, :start]
    retries 2
    retry_delay 5
end