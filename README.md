![PRUN logo](http://blog.lebrijo.com/wp-content/uploads/2014/10/logo-plumbadge-150x150.png)

# PRUN server = PostgreSQL + Ruby + Ubuntu + Nginx

Supported by OpenSSH + Chef-solo + Supervisor

Based on:

* Ubuntu 14.04 LTS and PostgreSQL 9.3
* Ruby 2.1.2

Name 'Prun' means 'Plum' in Romanian language.

Based on [Base server](https://registry.hub.docker.com/u/jlebrijo/base/)

## Run the container

Download image and run a container

```
docker pull jlebrijo/prun
docker run -d -p 2222:22 -i jlebrijo/prun
```

## Inject your SSH public key:

In order to have SSH access you have to copy your public keys into the container. I recommend the following script:

```
      # Container folder
      if sudo test -d "/var/lib/docker/aufs"; then
        CONTAINERS_DIR=/var/lib/docker/aufs/mnt
      elif sudo test -d "/var/lib/docker/aufs"; then
        CONTAINERS_DIR=/var/lib/docker/btrfs/subvolumes
      fi

      ID=$(docker inspect -f   '{{.Id}}' #{container_name})
      SSH_DIR=$CONTAINERS_DIR/$ID/root/.ssh
      echo SSH container folder is $SSH_DIR
      if sudo test ! -d "$SSH_DIR" ; then
        sudo mkdir $SSH_DIR
      fi

      echo Copying authorized_keys and id_rsa.pub files
      sudo touch $SSH_DIR/authorized_keys
      sudo cat ~/.ssh/authorized_keys | sudo tee -a $SSH_DIR/authorized_keys
      sudo cat ~/.ssh/id_rsa.pub | sudo tee -a $SSH_DIR/authorized_keys
      sudo chmod 600 $SSH_DIR/authorized_keys
```

## DevOps workflow for Rails Developers

For a detailed day-to-day operations on a PRUN server let's read ["DevOps workflow with Docker/Chef/Capistrano for Rails Applications"](http://blog.lebrijo.com/?p=587). Here you will see how to:

* Manage configuration with Chef `knife solo cook root@lebrijo.com -p 2222`.
* Make Continuous Deployments with Capistrano `cap production deploy`.
* Run server in localhost and in a [DigitalOcean](https://www.digitalocean.com/?refcode=704e0b409e24) CoreOS server.

## Contributing

1. Fork it ( https://github.com/[my-github-username]/prun-ops/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

[MIT License](http://opensource.org/licenses/MIT). Made by [Lebrijo.com](http://lebrijo.com)

