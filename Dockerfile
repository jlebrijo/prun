# PRUN server = PostgreSQL + Ruby + Ubuntu + Nginx
# OpenSSH + Chef-solo + Supervisor
FROM jlebrijo/base
MAINTAINER Juan Lebrijo "juan@lebrijo.com"

# DEPENDENCIES
RUN apt-get -y update

# RUBY
ENV RUBY_VERSION 2.2.0

RUN apt-get install -y git build-essential libsqlite3-dev libssl-dev gawk libreadline6-dev libyaml-dev sqlite3 autoconf libgdbm-dev libncurses5-dev automake libtool bison pkg-config libffi-dev
RUN git clone https://github.com/sstephenson/ruby-build.git /root/ruby-build
RUN /root/ruby-build/install.sh

RUN ruby-build --verbose $RUBY_VERSION /usr/local/ruby/$RUBY_VERSION

RUN echo PATH=$PATH:/usr/local/ruby/$RUBY_VERSION/bin > /etc/environment

RUN echo gem: --no-ri --no-rdoc > /root/.gemrc
ENV PATH $PATH:/usr/local/ruby/$RUBY_VERSION/bin
RUN gem install bundler
RUN gem install thin
RUN thin install

# Supervisor
COPY supervisord.conf /etc/supervisor/conf.d/thin.conf