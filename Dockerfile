FROM sameersbn/ubuntu:16.04.20180124
LABEL maintainer="sameer@damagehead.com"

ENV GITLAB_VERSION=10.6.1 \
    RUBY_VERSION=2.3 \
    GOLANG_VERSION=1.9.4 \
    GITLAB_SHELL_VERSION=6.0.4 \
    GITLAB_WORKHORSE_VERSION=4.0.0 \
    GITLAB_PAGES_VERSION=0.7.1 \
    GITALY_SERVER_VERSION=0.91.0 \
    GITLAB_USER="git" \
    GITLAB_HOME="/home/git" \
    GITLAB_LOG_DIR="/var/log/gitlab" \
    GITLAB_CACHE_DIR="/etc/docker-gitlab" \
    RAILS_ENV=production \
    NODE_ENV=production

ENV GITLAB_INSTALL_DIR="${GITLAB_HOME}/gitlab" \
    GITLAB_SHELL_INSTALL_DIR="${GITLAB_HOME}/gitlab-shell" \
    GITLAB_WORKHORSE_INSTALL_DIR="${GITLAB_HOME}/gitlab-workhorse" \
    GITLAB_PAGES_INSTALL_DIR="${GITLAB_HOME}/gitlab-pages" \
    GITLAB_GITALY_INSTALL_DIR="${GITLAB_HOME}/gitaly" \
    GITLAB_DATA_DIR="${GITLAB_HOME}/data" \
    GITLAB_BUILD_DIR="${GITLAB_CACHE_DIR}/build" \
    GITLAB_RUNTIME_DIR="${GITLAB_CACHE_DIR}/runtime"

ENV GITLAB_REPOS_DIR="${GITLAB_REPOS_DIR:-$GITLAB_DATA_DIR/repositories}"
ENV GITLAB_DOWNLOADS_DIR="${GITLAB_DOWNLOADS_DIR:-$GITLAB_TEMP_DIR/downloads}"
ENV GITLAB_SHARED_DIR="${GITLAB_SHARED_DIR:-$GITLAB_DATA_DIR/shared}"
ENV GITLAB_ARTIFACTS_DIR="${GITLAB_ARTIFACTS_DIR:-$GITLAB_SHARED_DIR/artifacts}"
ENV GITLAB_PAGES_DIR="${GITLAB_PAGES_DIR:-$GITLAB_SHARED_DIR/pages}"
ENV GITLAB_LFS_OBJECTS_DIR="${GITLAB_LFS_OBJECTS_DIR:-$GITLAB_SHARED_DIR/lfs-objects}"


RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv E1DD270288B4E6030699E45FA1715D88E1DF1F24 \
 && echo "deb http://ppa.launchpad.net/git-core/ppa/ubuntu xenial main" >> /etc/apt/sources.list \
 && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 80F70E11F0F0D5F10CB20E62F5DA5F09C3173AA6 \
 && echo "deb http://ppa.launchpad.net/brightbox/ruby-ng/ubuntu xenial main" >> /etc/apt/sources.list \
 && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 8B3981E7A6852F782CC4951600A6F0A3C300EE8C \
 && echo "deb http://ppa.launchpad.net/nginx/stable/ubuntu xenial main" >> /etc/apt/sources.list \
 && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
 && echo 'deb http://apt.postgresql.org/pub/repos/apt/ xenial-pgdg main' > /etc/apt/sources.list.d/pgdg.list \
 && wget --quiet -O - https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - \
 && echo 'deb https://deb.nodesource.com/node_8.x xenial main' > /etc/apt/sources.list.d/nodesource.list \
 && wget --quiet -O - https://dl.yarnpkg.com/debian/pubkey.gpg  | apt-key add - \
 && echo 'deb https://dl.yarnpkg.com/debian/ stable main' > /etc/apt/sources.list.d/yarn.list \
 && apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y supervisor logrotate locales curl \
      nginx openssh-server mysql-client postgresql-client redis-tools \
      git-core ruby${RUBY_VERSION} python2.7 python-docutils nodejs yarn gettext-base \
      libmysqlclient20 libpq5 zlib1g libyaml-0-2 libssl1.0.0 \
      libgdbm3 libreadline6 libncurses5 libffi6 \
      libxml2 libxslt1.1 libcurl3 libicu55 \
      libre2-dev \
      tzdata \
 && update-locale LANG=C.UTF-8 LC_MESSAGES=POSIX \
 && locale-gen en_US.UTF-8 \
 && DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales \
 && gem install --no-document bundler \
 && rm -rf /var/lib/apt/lists/*

COPY assets/build/ ${GITLAB_BUILD_DIR}/
RUN bash ${GITLAB_BUILD_DIR}/install.sh

COPY assets/runtime/ ${GITLAB_RUNTIME_DIR}/

COPY entrypoint.sh /sbin/entrypoint.sh
RUN chmod 755 /sbin/entrypoint.sh

COPY init.sh /sbin/init.sh
RUN chmod 755 /sbin/init.sh

EXPOSE 22/tcp 80/tcp 443/tcp

WORKDIR ${GITLAB_INSTALL_DIR}

#COPY bitmex-root.crt /usr/local/share/ca-certificates

RUN set -ex && \
    update-ca-certificates --fresh

RUN /sbin/init.sh

ADD noop.sh /bin/chmod
ADD noop.sh /bin/chown

USER git
ENTRYPOINT ["/sbin/entrypoint.sh"]
CMD ["app:start"]
