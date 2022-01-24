FROM registry.cloudogu.com/official/base:3.12.4-2

LABEL MAINTAINER="hello@cloudogu.com" \
        NAME="official/mysql" \
        VERSION="1.0.0-1"

ENV MARIADB_VERSION="10.4.22-r0"

# Add user and install software
RUN adduser -S -h "/var/lib/mysql" -s /sbin/nologin -u 1000 mysql \
  && apk add --update mariadb="${MARIADB_VERSION}" mariadb-client="${MARIADB_VERSION}" \
  && rm -rf /var/cache/apk/*  \
  && mkdir /var/run/mysqld \
  && chown -R mysql:mysql /var/lib/mysql /var/run/mysqld


# Bind server to 0.0.0.0
RUN sed -i "s|.*bind-address\s*=.*|bind-address=0.0.0.0|g" /etc/my.cnf.d/mariadb-server.cnf

COPY resources/ /

VOLUME "/var/lib/mysql"

EXPOSE 3306

USER mysql

# FIRE IT UP
CMD ["/bin/bash", "/startup.sh"]
