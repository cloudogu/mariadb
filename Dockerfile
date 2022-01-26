FROM registry.cloudogu.com/official/base:3.12.4-2

LABEL MAINTAINER="hello@cloudogu.com" \
        NAME="official/mariadb" \
        VERSION="10.4.22-1"

ENV MARIADB_VERSION="10.4.22-r0" \
    USER=mariadb \
    GROUP=mariadb \
    MARIADB_VOLUME=/var/lib/mariadb

# Add user and install software
RUN set -eux -o pipefail \
  && addgroup -S "${GROUP}" -g 1000 \
  && adduser -S -h "${MARIADB_VOLUME}" -G "${GROUP}" -u 1000 -s /sbin/nologin "${USER}" \
  && apk add --update mariadb="${MARIADB_VERSION}" mariadb-client="${MARIADB_VERSION}" \
  # add symlinks to simplify shell tests because dashed binaries are hard to mock
  && ln -s /usr/bin/mariadb-install-db /usr/bin/mariadb_install_db \
  && ln -s /usr/bin/mariadbd-safe /usr/bin/mariadbd_safe \
  && rm -rf /var/cache/apk/*  \
  && mkdir /var/run/mysqld \
  && chown -R "${USER}":"${GROUP}" "${MARIADB_VOLUME}" /var/run/mysqld \
  && sed -i "s|.*bind-address\s*=.*|bind-address=0.0.0.0|g" /etc/my.cnf.d/mariadb-server.cnf \
  && sed -i "s|^skip-networking$|#skip-networking|" /etc/my.cnf.d/mariadb-server.cnf

COPY resources/ /

VOLUME "${MARIADB_VOLUME}"

EXPOSE 3306

HEALTHCHECK CMD doguctl healthy mariadb || exit 1

USER "${USER}"

CMD ["/startup.sh"]
