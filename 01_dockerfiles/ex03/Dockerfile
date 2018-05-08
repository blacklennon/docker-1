FROM ubuntu:14.04

RUN apt-get update && apt-get install -y \
	curl \
	openssh-server \
	ca-certificates \
	sudo \
	build-essential \
	zlib1g-dev \
	libyaml-dev \
	libssl-dev \
	libgdbm-dev \
	libreadline-dev \
	libncurses5-dev \
	libffi-dev \
	checkinstall \
	libxml2-dev \
	libxslt-dev \
	libcurl4-openssl-dev \
	libicu-dev \
	logrotate \
	rsync \
	python-docutils \
	pkg-config \
	cmake \
	libexpat1-dev \
	gettext \
	libz-dev

WORKDIR /tmp

RUN curl -L --remote-name --progress https://www.kernel.org/pub/software/scm/git/git-2.16.2.tar.gz && \
	echo '9acc4339b7a2ab484eea69d705923271682b7058015219cf5a7e6ed8dee5b5fb  git-2.16.2.tar.gz' | shasum -a256 -c - && tar -xzf git-2.16.2.tar.gz && \
	cd git-2.16.2/ && \
	./configure && \
	make prefix=/usr/local all && \
	make prefix=/usr/local install && \
	cd /tmp && rm -rf *

RUN git clone https://code.googlesource.com/re2 && cd re2 && \
	make && \
	make test && \
	make install && \
	make testinstall && \
	cd /tmp && rm -rf *

RUN mkdir ruby && cd ruby && \
	curl -L --remote-name --progress https://cache.ruby-lang.org/pub/ruby/2.3/ruby-2.3.6.tar.gz && \
	echo '4e6a0f828819e15d274ae58485585fc8b7caace0  ruby-2.3.6.tar.gz' | shasum -c - && tar xzf ruby-2.3.6.tar.gz && \
	cd ruby-2.3.6 && \
	./configure --disable-install-rdoc && \
	make && make install && \
	cd /tmp && rm -rf *

RUN gem install bundler --no-ri --no-rdoc

RUN curl -L --remote-name --progress https://storage.googleapis.com/golang/go1.8.3.linux-amd64.tar.gz && \
	echo '1862f4c3d3907e59b04a757cfda0ea7aa9ef39274af99a784f5be843c80c6772  go1.8.3.linux-amd64.tar.gz' | shasum -a256 -c - && tar -C /usr/local -xzf go1.8.3.linux-amd64.tar.gz && \
	sudo ln -sf /usr/local/go/bin/go /usr/local/bin/go && \
	sudo ln -sf /usr/local/go/bin/godoc /usr/local/bin/godoc && \
	sudo ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt && \
	rm -rf *

RUN curl --location https://deb.nodesource.com/setup_8.x | sudo bash - && apt-get install -y nodejs

RUN curl --silent --show-error https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add - && echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list && \
	apt-get update && apt-get install -y yarn postgresql-9.3 postgresql-client-9.3 libpq-dev postgresql-contrib-9.3

RUN adduser --disabled-login --gecos 'GitLab' git

RUN service postgresql start && \
	sudo -u postgres psql -d template1 -c "CREATE USER git WITH PASSWORD 'secure password' CREATEDB;" && \
	sudo -u postgres psql -c "UPDATE pg_database SET datistemplate = FALSE WHERE datname = 'template1';" && \
	sudo -u postgres psql -c "DROP DATABASE template1;" && \
	sudo -u postgres psql -c "CREATE DATABASE template1 WITH TEMPLATE = template0 ENCODING = 'UNICODE';" && \
	sudo -u postgres psql -c "UPDATE pg_database SET datistemplate = TRUE WHERE datname = 'template1';" && \
	sudo -u postgres psql -d template1 -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;" && \	
	sudo -u postgres psql -d template1 -c "CREATE DATABASE gitlabhq_production OWNER git;"

RUN apt-get update && apt-get install -y redis-server && \
	cp /etc/redis/redis.conf /etc/redis/redis.conf.orig && \
	sed 's/^port .*/port 0/' /etc/redis/redis.conf.orig | sudo tee /etc/redis/redis.conf && \
	echo 'unixsocket /var/run/redis/redis.sock' | sudo tee -a /etc/redis/redis.conf && \
	echo 'unixsocketperm 770' | sudo tee -a /etc/redis/redis.conf && \
	mkdir /var/run/redis && \
	chown redis:redis /var/run/redis && \
	chmod 755 /var/run/redis && \
	service redis-server restart && \
	usermod -aG redis git

WORKDIR /home/git

RUN sudo -u git -H git clone https://gitlab.com/gitlab-org/gitlab-ce.git -b 10-6-stable gitlab

WORKDIR /home/git/gitlab

COPY gitlab.yml config/gitlab.yml

RUN sudo -u git -H cp config/secrets.yml.example config/secrets.yml && \
	sudo -u git -H chmod 0600 config/secrets.yml && \
	chown -R git log/ && chown -R git tmp/ && chmod -R u+rwX,go-w log/ && chmod -R u+rwX tmp/ && \
	chmod -R u+rwX tmp/pids/ && chmod -R u+rwX tmp/sockets/ && \
	sudo -u git -H mkdir public/uploads/ && \
	chmod 0700 public/uploads && chmod -R u+rwX builds/ && \
	chmod -R u+rwX shared/artifacts/ && \
	chmod -R ug+rwX shared/pages/ && \
	sudo -u git -H cp config/unicorn.rb.example config/unicorn.rb && \
	sudo -u git -H cp config/initializers/rack_attack.rb.example config/initializers/rack_attack.rb && \
	sudo -u git -H git config --global core.autocrlf input && \
	sudo -u git -H git config --global gc.auto 0 && \
	sudo -u git -H git config --global repack.writeBitmaps true && \
	sudo -u git -H git config --global receive.advertisePushOptions true && \
	sudo -u git -H cp config/resque.yml.example config/resque.yml && \
	sudo -u git cp config/database.yml.postgresql config/database.yml && \
	sudo -u git -H chmod o-rwx config/database.yml

RUN sudo -u git -H bundle install --deployment --without development test mysql aws kerberos

RUN service redis-server start && sudo -u git -H bundle exec rake gitlab:shell:install REDIS_URL=unix:/var/run/redis/redis.sock RAILS_ENV=production SKIP_STORAGE_VALIDATION=true

RUN sudo -u git -H bundle exec rake "gitlab:workhorse:install[/home/git/gitlab-workhorse]" RAILS_ENV=production

RUN service postgresql start && service redis-server start && sh -c '/bin/echo -e "yes\n" | sudo -u git -H bundle exec rake gitlab:setup RAILS_ENV=production'

RUN sudo cp lib/support/init.d/gitlab /etc/init.d/gitlab && sudo update-rc.d gitlab defaults 21

RUN sudo -u git -H bundle exec rake "gitlab:gitaly:install[/home/git/gitaly]" RAILS_ENV=production && \
	sudo chmod 0700 /home/git/gitlab/tmp/sockets/private && \
	sudo chown git /home/git/gitlab/tmp/sockets/private && \
	sudo cp lib/support/logrotate/gitlab /etc/logrotate.d/gitlab && \
	sudo -u git -H bundle exec rake gettext:compile RAILS_ENV=production

RUN sudo -u git -H yarn install --production --pure-lockfile && \
	sudo -u git -H bundle exec rake gitlab:assets:compile RAILS_ENV=production NODE_ENV=production

RUN chmod -R ug+rwX,o-rwx /home/git/repositories && \
	chmod -R ug-s /home/git/repositories && \
	find /home/git/repositories -type d -print0 | sudo xargs -0 chmod g+s

RUN cd /tmp && curl -L --remote-name http://nginx.org/keys/nginx_signing.key && apt-key add nginx_signing.key && \
	echo 'deb http://nginx.org/packages/mainline/ubuntu/ trusty nginx\ndeb-src http://nginx.org/packages/mainline/ubuntu/ trusty nginx' >> /etc/apt/sources.list && \
	apt-get update && apt-get install -y nginx

RUN rm -f /etc/nginx/conf.d/default.conf /home/git/gitlab-shell/config.yml

COPY ./gitlab-ssl /etc/nginx/conf.d/gitlab-ssl.conf

RUN mkdir -p /etc/nginx/ssl && cd /etc/nginx/ssl && echo 'FR\nFrance\nParis\nGitlab\nissou\nlocalhost\nissou@issou.com\n' | openssl req -newkey rsa:2048 -x509 -nodes -days 3560 -out gitlab.crt -keyout gitlab.key && chmod o-r gitlab.key

EXPOSE 80:80

EXPOSE 22:22

EXPOSE 443:443

COPY ./config.yml /home/git/gitlab-shell/config.yml

COPY ./entrypoint.sh /entrypoint.sh

RUN chmod 755 /entrypoint.sh

ENTRYPOINT /entrypoint.sh
