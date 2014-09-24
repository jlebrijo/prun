# Docker

## Creating Docker Image

Create a Dockerfile `./Dockerfile`:

* PRUN server = PostgreSQL + Ruby + Ubuntu + Nginx
* Supported by OpenSSH + Chef-solo + Supervisor

Build the image:

```
docker build -t jlebrijo/prun .
```

Tag this as ruby version:

```
docker tag jlebrijo/prun:latest jlebrijo/prun:ruby-212
```

## Upload Image to hub.docker.com

```
docker login
docker push jlebrijo/prun
```

## Run a Container

Run a container:

```
docker run -d -m 8g --cpuset 0-7 --name rails_stack -p 2222:22 -i jlebrijo/prun
```

Inject your key to container:

```
sshpass -p 'J3mw?$_6' ssh-copy-id -o "StrictHostKeyChecking no" -i ~/.ssh/id_rsa.pub root@localhost -p 2222
```
---

Put in /etc/hosts:

```
127.0.0.1       surprize.me
127.0.0.1       app.surprize.me
127.0.0.1       www.surprize.me
```

So that we can use `surprize.me` instead of `localhost`

---

# Useful commands on Image/Configuration/Deploy tests

```bash
docker run -t --name rails_stack -p 2222:22 -i jlebrijo/prun /bin/bash

docker rm -f $(docker ps -a -q) && docker rmi jlebrijo/prun

docker build -t jlebrijo/prun .

docker run -d -m 8g --cpuset 0-7 --name surprizeme -p 2222:22 -p 5000:3000 -p 5001:3001 -p 80:80 -i jlebrijo/prun

ssh-keygen -f "/home/jlebrijo/.ssh/known_hosts" -R [localhost]:2222
sshpass -p 'J3mw?$_6' ssh-copy-id -o "StrictHostKeyChecking no" -i ~/.ssh/id_rsa.pub root@localhost -p 2222
ssh root@localhost -p 2222
```

# Chef

## Create Chef kitchen structure

Create repo:

```
mkdir ops && cd ops
rbenv local 2.1.2
git init
```

Create a Gemfile:

```
source 'https://rubygems.org'

gem 'knife-solo'
gem 'librarian-chef'
```

And: `bundle install`

Create Kitchen folder structure: `knife solo init .`

Create the Cheffile with all needed dependencies: `librarian-chef init`

```
site 'https://supermarket.getchef.com/api/v1'

cookbook 'ssh_known_hosts'
```

## The recipe

Create `site-cookbooks/rails-stack/recipes/default.rb`:

```ruby
execute "apt-get update" do
  command "apt-get update"
end

# Add Deployer keys
cookbook_file "id_rsa" do
  source "id_rsa"
  path "/root/.ssh/id_rsa"
  mode 0600
  action :create_if_missing
end
cookbook_file "id_rsa.pub" do
  source "id_rsa.pub"
  path "/root/.ssh/id_rsa.pub"
  mode 0644
  action :create_if_missing
end

# Add known hosts
ssh_known_hosts_entry 'github.com'
ssh_known_hosts_entry 'bitbucket.org'

# PGSQL configuration
service 'postgresql' do
  action :restart
end
bash "create pg_user and pg_ddbb" do
  code <<-EOH
  sudo -u postgres psql -c "create role pg_user with createdb login password 'G7sj_#?0';"
  sudo -u postgres psql -c "create database pg_ddbb;"
  sudo -u postgres psql -c "grant all privileges on database pg_ddbb to pg_user;"
  EOH
  not_if "sudo -u postgres psql -c \"\\du\" | grep pg_user"
end

# Rails dependencies
package "libmagickwand-dev"

%w(www app).each_with_index do |app, i|
  directory "/var/www/#{app}/shared/config/" do
    recursive true
  end
  cookbook_file "database.yml" do
    path "/var/www/#{app}/shared/config/database.yml"
  end
  execute "/usr/local/ruby/2.1.2/bin/thin config -C /etc/thin/#{app}.yml -c /var/www/#{app}/current -l log/thin.log -e production --servers 1 --port #{3000 + i}"
end

directory "/var/www/www/shared/public/uploads/" do
  recursive true
end
directory "/var/www/app/shared/public/" do
  recursive true
end
link "/var/www/app/shared/public/uploads" do
  to "/var/www/www/shared/public/uploads"
end

# NGINX
%w(www app).each_with_index do |app, i|
  template "/etc/nginx/conf.d/#{app}.conf" do
    source "nginx.conf.erb"
    variables app: app, port: 3000 + i
  end
end

service 'nginx' do
  action :restart
end
```

Operations with Keys:

 * Generate Keys with `ssh-keygen -t rsa -C "ops@surprize.me"` 
 * Copy them to the folder 'site-cookbooks/rails-stack/files/default'.
 * Add id_rsa.pub key to your repos SSH Keys (Github and Bitbucket)
 
Finally we should add the recipe dependencies at 'site-cookbooks/rails-stack/metadata.rb':

```
## Recipe dependencies
depends 'ssh_known_hosts'
```

## Run Chef recipe over LOCAL container

We need to create the node copying at 'nodes/localhost.json'

```
{
  "run_list": [
    "recipe[rails-stack]"
  ]
}
```

Then cook the recipe:

```
knife solo cook root@localhost -p 2222
```

# Capistrano 3 in the apps

To run Capistrano 3 in the app, add to hour Gemfile: `gem "capistrano-rails"` bundle it `bundle install` and create basic files `capify .`

Capfile should include these requirements:

```ruby
require 'capistrano/setup'
require 'capistrano/deploy'
require 'capistrano/rails'
require 'capistrano/bundler'
require 'capistrano/rails/assets'
require 'capistrano/rails/migrations'
Dir.glob('lib/capistrano/tasks/*.rake').each { |r| import r }
```

Your config/deploy.rb (db:setup task should be in main project):

```ruby
lock '3.2.1'

set :application, 'www'
set :linked_files, %w{config/database.yml}
set :linked_dirs, %w{public/uploads}

namespace :deploy do
  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      # Your restart mechanism here, for example:
      # execute :touch, release_path.join('tmp/restart.txt')
      execute "service thin restart"
    end
  end
  after :publishing, :restart
end

namespace :db do
  desc 'First DDBB setup'
  task :setup do
    on roles(:all) do
      within release_path do
        with rails_env: fetch(:stage) do
          execute :rake, 'db:schema:load'
          execute :rake, 'db:seed'
        end
      end
    end
  end
end
```

config/deploy/local.rb:

```
server "localhost", user: 'root', roles: %w{web app}, port: 2222
set :repo_url,  "git@bitbucket.org:surprizeme/www.git"
```

Local should be a exact copy of production env  so: `cd config/environments/ && cp production.rb local.rb`

Remember change this line in both files: `config.assets.compile = true`

First deploy:

```
cap local deploy db:setup
```

# DigitalOcean installation

---

Remove or comment all /etc/hosts configurations

---

Create a CoreOS Droplet this will give you an IP `104.131.120.115`

With your registrar create records needed to this IP:

```
A      @    104.131.120.115
CNAME  www  @
CNAME  app  @
```
Create Docker container:

```
ssh core@surprize.me
docker pull -t jlebrijo/prun
docker run -d --name surprizeme -p 2222:22 -p 5000:3000 -p 5001:3001 -p 80:80 -i jlebrijo/prun
```

Manual configuration of our public key:

```
ssh root@localhost -p 2222
-> J3mw?$_6
mkdir .ssh && vi .ssh/authorized_keys
-> ssh-rsa AAAAB3Nz.....
```

Cook with Chef and Deploy with Capistrano:

```
cd ops && knife solo cook root@surprize.me -p 2222
cd www && cap production deploy db:setup
cd app && cap production deploy
```