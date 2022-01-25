#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

mkdir -p /var/run/mysqld
chown -R mysql: /var/run/mysqld

# installation
if [ ! -f /var/lib/mysql/ibdata1 ]; then
    # set stage for health check
    doguctl state installing

    # install database
    mysql_install_db --user=mysql --datadir="/var/lib/mysql"

    # start daemon in background
    /usr/bin/mysqld_safe --user=mysql &

    # create random root password
    MYSQL_ROOT_PASSWORD=$(doguctl random)

    # store the password encrypted
    doguctl config -e password "${MYSQL_ROOT_PASSWORD}"

    # wait until mysql is ready to accept connections
    doguctl wait --port 3306

    # set generated root password
    mysql -umysql -e "GRANT ALL PRIVILEGES ON *.* TO root@'%' IDENTIFIED BY \"${MYSQL_ROOT_PASSWORD}\" WITH GRANT OPTION;"

    # secure the installation
    # https://github.com/twitter-forks/mysql/blob/master/scripts/mysql_secure_installation.sh
    mysql -umysql -e "DROP DATABASE test;"
    mysql -umysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%'"

    #remove anonymous user
    mysql -umysql -e "DELETE FROM mysql.user WHERE User=\";\""

    # remove remote root
    mysql -umysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"

    # reload privilege tables
    mysql -umysql -e "FLUSH PRIVILEGES;"

    # set stage for health check
    doguctl state ready

    # reattach daemon
    wait
else
  # set stage for health check
  doguctl state ready

  # start mysql
  exec /usr/bin/mysqld_safe --user=mysql
fi
