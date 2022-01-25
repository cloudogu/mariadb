#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

DATABASE_STORAGE=/var/lib/mysql/ibdata1

function runMain() {
  mkdir -p /var/run/mysqld
  chown -R mysql: /var/run/mysqld

  if [[ ! -f "${DATABASE_STORAGE}" ]]; then
    initMariaDB
  fi

  regularMariaDBStart
}

function initMariaDB() {
  doguctl state installing

  mysql_install_db --user=mysql --datadir="/var/lib/mysql"

  # start daemon in background
  mysqld_safe --user=mysql&

  pid=$!

  applySecurityConfiguration

  kill "${pid}"

  wait "${pid}" || true
}

function regularMariaDBStart() {
  doguctl state ready

  mysqld_safe --user=mysql
}

function applySecurityConfiguration() {
  # create random root password
  MYSQL_ROOT_PASSWORD=$(doguctl random)

  # store the password encrypted
  doguctl config -e password "${MYSQL_ROOT_PASSWORD}"

  # wait until mysql is ready to accept connections
  doguctl wait --port 3306

  # set generated root password
  mariadb -umysql -e "GRANT ALL PRIVILEGES ON *.* TO root@'%' IDENTIFIED BY \"${MYSQL_ROOT_PASSWORD}\" WITH GRANT OPTION;"

  # secure the installation
  # https://github.com/twitter-forks/mysql/blob/master/scripts/mysql_secure_installation.sh
  mariadb -umysql -e "DROP DATABASE test;"
  mariadb -umysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%'"

  # remove anonymous user
  mariadb -umysql -e "DELETE FROM mysql.user WHERE User=\";\""

  # remove remote root
  mariadb -umysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"

  # reload privilege tables
  mariadb -umysql -e "FLUSH PRIVILEGES;"
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  runMain
fi
