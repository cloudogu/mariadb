FROM registry.cloudogu.com/official/base:3.14.2-2

LABEL MAINTAINER="hello@cloudogu.com" \
        NAME="official/mariadb" \
        VERSION="10.5.13-0"

ENV MARIADB_VERSION="10.5.13-r0" \
    USER=mariadb \
    GROUP=mariadb \
    MARIADB_VOLUME=/var/lib/mariadb \
    STARTUP_DIR=""

# Add user and install software
RUN set -eux -o pipefail \
  && addgroup -S "${GROUP}" -g 1000 \
  && adduser -S -h "${MARIADB_VOLUME}" -G "${GROUP}" -u 1000 -s /sbin/nologin "${USER}" \
  && apk add --update mariadb="${MARIADB_VERSION}" mariadb-client="${MARIADB_VERSION}" \
  # add symlinks to simplify shell tests because dashed binaries are hard to mock
  && ln -s /usr/bin/mariadb-install-db /usr/bin/mariadb_install_db \
  && ln -s /usr/bin/mariadbd-safe /usr/bin/mariadbd_safe \
  && ln -s /usr/bin/mariadbd-dump /usr/bin/mariadb_dump \
  # support docker logging to stdout
  && mkdir -p /opt/lib/mariadb \
  && ln -sf /dev/stdout /opt/lib/mariadb/mariadb.err \
  && rm -rf /var/cache/apk/*  \
  && mkdir /var/run/mysqld \
  && chown -R "${USER}":"${GROUP}" "${MARIADB_VOLUME}" /var/run/mysqld /opt/lib/mariadb \
  # create a config dir that is writable as unprivileged mariadb user during doguctl template
  && mkdir -p /etc/my.cnf.dogu.d/ \
  && chown "${USER}":"${GROUP}" /etc/my.cnf.dogu.d/ \
  # change settings that come with the Alpine package
  && sed -i "s|.*bind-address\s*=.*|bind-address=0.0.0.0|g" /etc/my.cnf.d/mariadb-server.cnf \
  && sed -i "s|^skip-networking$|#skip-networking|" /etc/my.cnf.d/mariadb-server.cnf

COPY resources/ /

VOLUME "${MARIADB_VOLUME}"

EXPOSE 3306

HEALTHCHECK CMD doguctl healthy mariadb || exit 1

# Re-using user and group outweighs negative outcomes
# dockerfile_lint - ignore
USER "${USER}":"${GROUP}"

CMD ["/startup.sh"]
