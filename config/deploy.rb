# config valid only for current version of Capistrano
lock '3.4.0'

set :use_sudo, false
set :log_level, :info

set :user, 'ubuntu'
set :application, 'sharetribe'

set :scm, :git
set :repo_url, 'git@github.com:johnwaldo/sharetribe.git'
set :branch, 'cee93cd840d83bf784e638530bb8a50dc8bc21ee'

set :deploy_to, "/home/#{fetch :user}/#{fetch :application}-#{fetch :stage}"
set :linked_files, fetch(:linked_files, []).push(*%w{config/database.yml config/config.yml})
set :linked_dirs, fetch(:linked_dirs, []).push(*%w{bin log tmp/pids tmp/cache tmp/sockets public/system})
set :keep_releases, 3
set :passenger_restart_with_touch, true

server 'custom.sharetribe.com', user: fetch(:user), roles: %w{web app db worker}