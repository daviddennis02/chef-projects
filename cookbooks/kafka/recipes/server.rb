#
# Cookbook:: kafka
# Recipe:: server
#
# Copyright:: 2024, The Authors, All Rights Reserved.

# In your cookbook's default recipe
  
# Install Java
apt_update 'update' do
  action :update
end

package 'openjdk-11-jdk' do
  action :install
end

# Install Kafka
kafka_home = '/opt/kafka'
# ENV['kafka_home'] = '/opt/kafka'

user 'kafka' do
  comment 'Kafka User'
  system true
  shell '/bin/false'
end

group 'kafka' do
  members 'kafka'
  system true
  append true
end

directory kafka_home do
  owner 'kafka'
  group 'kafka'
  mode '0755'
  action :create
end

# Download Kafka
remote_file "#{kafka_home}/kafka.tgz" do
  source 'https://downloads.apache.org/kafka/3.7.0/kafka_2.13-3.7.0.tgz'
  owner 'kafka'
  group 'kafka'
  mode '0644'
  action :create
  notifies :run, 'execute[extract_kafka]', :immediately
end

# Untar kafka zipped file
execute 'extract_kafka' do
  command "tar -xzf #{kafka_home}/kafka.tgz -C #{kafka_home} --strip-components=1"
  action :nothing
end

# Set up configuration for kafka
template "#{kafka_home}/config/server.properties" do
  source 'server.properties.erb'
  owner 'kafka'
  group 'kafka'
  mode '0644'
  variables(
    :broker_id => node['kafka']['broker_id'],
    :port => node['kafka']['port']
    # Add more configuration variables as needed
  )
end

# Set up configuration for Zookeeper
template "#{kafka_home}/config/zookeeper.properties" do
  source 'zookeeper.properties.erb'
  owner 'kafka'
  group 'kafka'
  mode '0644'
end

# Create init.d script for Zookeeper
template "/etc/init.d/zookeeper" do
  source 'zookeeper_initd.erb'
  owner 'kafka'
  group 'kafka'
  mode '0755'
  notifies :start, 'service[zookeeper]'
end

# Create init.d script for Kafka
template "/etc/init.d/kafka" do
  source 'kafka_initd.erb'
  owner 'kafka'
  group 'kafka'
  mode '0755'
  notifies :start, 'service[kafka]'
end

# Start Zookeeper service
service 'zookeeper' do
  supports :status => true, :restart => true, :reload => true
  action [:enable, :start]
  retries 2
  retry_delay 5
end  

# Start Kafka service
service 'kafka' do
  supports :status => true, :restart => true, :reload => true
  action [:enable, :start]
  retries 2
  retry_delay 5
end  