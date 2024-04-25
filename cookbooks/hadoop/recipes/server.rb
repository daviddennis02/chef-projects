#
# Cookbook:: hadoop
# Recipe:: default
#
# Copyright:: 2024, The Authors, All Rights Reserved.

# Install Java
apt_update 'update' do
  action :update
end

package 'openjdk-11-jdk' do
  action :install
end

# execute "set_java_home" do
#   command "export JAVA_HOME="
# end

# Install hadoop
hadoop_home = '/opt/hadoop'
hadoop_envfile = '/opt/hadoop/etc/hadoop/hadoop-env.sh'
hadoop_version = '3.3.6'

user 'hadoop' do
    comment 'hadoop User'
    system true
    shell '/bin/false'
end
  
  group 'hadoop' do
    members 'hadoop'
    system true
    append true
  end
  
  directory hadoop_home do
    owner 'hadoop'
    group 'hadoop'
    mode '0755'
    action :create
  end

# Download hadoop
remote_file "#{hadoop_home}/hadoop.tgz" do
  source "https://dlcdn.apache.org/hadoop/common/hadoop-#{hadoop_version}/hadoop-#{hadoop_version}.tar.gz"
  owner 'hadoop'
  group 'hadoop'
  mode '0644'
  action :create
  notifies :run, 'execute[extract_hadoop]', :immediately
end

# Untar hadoop zipped file
execute 'extract_hadoop' do
  command "tar -xzf #{hadoop_home}/hadoop.tgz -C #{hadoop_home} --strip-components=1"
  action :nothing
  notifies :run, 'execute[java_home_export]', :immediately
end

# Update the JAVA_HOME in the hadoop_env.sh file
execute 'java_home_export' do
  command "echo export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64/ >> #{hadoop_envfile}"
  action :nothing
end

# Run the hadoop command
execute 'execute_hadoop' do
  command "#{hadoop_home}/bin/hadoop"
  action :nothing
end

# Test hadoop installation
execute 'test_hadoop' do
    command "#{hadoop_home}/bin/hadoop"
    action :nothing
end

# create test input directory
directory '/opt/hadoop/input' do
    owner 'hadoop'
    group 'hadoop'
    mode '0755'
    action :create
end

# copy the .xml sample files
execute 'copy_hadoop_sample_files' do
  command "cp #{hadoop_home}/etc/hadoop/*.xml #{hadoop_home}/input"
  action :nothing
end

# Run the MapReduce hadoop-mapreduce-examples program
execute 'execute_mapreduce' do
    command "#{hadoop_home}/bin/hadoop jar #{hadoop_home}/share/hadoop/mapreduce/hadoop-mapreduce-examples-#{hadoop_version}.jar grep #{hadoop_home}/input #{hadoop_home}/grep_result 'allowed[.]*'"
end

# Output the result
execute 'execute_mapreduce' do
    command "cat #{hadoop_home}/grep_result/*; ls -al  #{hadoop_home}/grep_result/;"
    notifies :write, 'log[debug_message]', :immediately
end

log 'debug_message' do
  # message lazy { "Debug information: #{node['your']['attribute']}" }
  message lazy { "Debug information:" }
  level :debug
  action :nothing
end