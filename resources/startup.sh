#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

DATABASE_STORAGE=/var/lib/mariadb/ibdata1

function runMain() {
  # the directory /var/run/mysqld is hardcoded in the mariadb config and should not be renamed to /var/run/mariadbd
  mkdir -p /var/run/mysqld
  chown -R mariadb:mariadb /var/run/mysqld

  if [[ ! -f "${DATABASE_STORAGE}" ]]; then
    initMariaDB
  fi

  regularMariaDBStart
}

function initMariaDB() {
  doguctl state installing

  mariadb_install_db --user=mariadb --datadir="/var/lib/mariadb"

  # start daemon in background
  mariadbd_safe --user=mariadb --datadir='/var/lib/mariadb' &

  pid=$!

  applySecurityConfiguration

  kill "${pid}"

  wait "${pid}" || true
}

function regularMariaDBStart() {
  doguctl state ready

  mariadbd_safe --user=mariadb --datadir='/var/lib/mariadb'
}

function applySecurityConfiguration() {
  # create random root password
  MARIADB_ROOT_PASSWORD=$(doguctl random)

  # store the password encrypted
  doguctl config -e password "${MARIADB_ROOT_PASSWORD}"

  # wait until mariadb is ready to accept connections
  doguctl wait --port 3306

  # set generated root password
  mariadb -umariadb -e "GRANT ALL PRIVILEGES ON *.* TO root@'%' IDENTIFIED BY \"${MARIADB_ROOT_PASSWORD}\" WITH GRANT OPTION;"

  # secure the installation
  # https://github.com/twitter-forks/mysql/blob/master/scripts/mysql_secure_installation.sh
  mariadb -umariadb -e "DROP DATABASE test;"
  mariadb -umariadb -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%'"

  # remove anonymous user
  mariadb -umariadb -e "DELETE FROM mysql.user WHERE User=\";\""

  # remove remote root
  mariadb -umariadb -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"

  # reload privilege tables
  mariadb -umariadb -e "FLUSH PRIVILEGES;"
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  runMain
fi
