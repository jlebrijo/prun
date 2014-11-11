# PRUN server = PostgreSQL + Ruby + Ubuntu + Nginx
# OpenSSH + Chef-solo + Supervisor
FROM ubuntu:14.04
MAINTAINER Juan Lebrijo "juan@lebrijo.com"

# DEPENDENCIES
RUN apt-get -y update

# CHEF-SOLO
RUN apt-get -y install curl build-essential libxml2-dev libxslt-dev git
RUN curl -L https://www.opscode.com/chef/install.sh | bash

# SSHD
RUN apt-get -y install openssh-server
RUN mkdir /var/run/sshd
RUN echo 'root:J3mw?$_6' | chpasswd
RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# RUBY 2.1.2
RUN apt-get install -y git build-essential libsqlite3-dev libssl-dev gawk libreadline6-dev libyaml-dev sqlite3 autoconf libgdbm-dev libncurses5-dev automake libtool bison pkg-config libffi-dev
RUN git clone https://github.com/sstephenson/ruby-build.git /root/ruby-build
RUN /root/ruby-build/install.sh
RUN ruby-build --verbose 2.1.2 /usr/local/ruby/2.1.2

RUN echo PATH=$PATH:/usr/local/ruby/2.1.2/bin > /etc/environment

RUN echo gem: --no-ri --no-rdoc > /root/.gemrc
ENV PATH $PATH:/usr/local/ruby/2.1.2/bin
RUN gem install bundler

# POSTGRESQL prepared for localhost connections
RUN export LANGUAGE=en_US.UTF-8
RUN apt-get -y install postgresql libpq-dev

RUN sed -i "s/#listen_addresses = 'localhost'/listen_addresses = 'localhost'/" /etc/postgresql/9.3/main/postgresql.conf
RUN sed -i "s/local   all             all                                     peer/local   all             all                                     md5/" /etc/postgresql/9.3/main/pg_hba.conf

# Nginx
RUN apt-get -y install nginx
RUN rm /etc/nginx/sites-enabled/default


# Supervisor
RUN apt-get install -y supervisor
RUN mkdir -p /var/log/supervisor

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

CMD ["/usr/bin/supervisord"]