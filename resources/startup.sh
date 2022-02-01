#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

DATABASE_VOLUME=/var/lib/mariadb
DATABASE_STORAGE="${DATABASE_VOLUME}/ibdata1"
DATABASE_CONFIG_DIR="${STARTUP_DIR}/etc/my.cnf.dogu.d"
DOGU_LOGLEVEL=2
CONTAINER_MEMORY_LIMIT_FILE=/sys/fs/cgroup/memory/memory.limit_in_bytes

function runMain() {
  # the directory /var/run/mysqld is hardcoded in the mariadb config and should not be renamed to /var/run/mariadbd
  mkdir -p /var/run/mysqld
  chown -R mariadb:mariadb /var/run/mysqld

  renderConfigFile

  if [[ ! -f "${DATABASE_STORAGE}" ]]; then
    initMariaDB
  fi

  regularMariaDBStart
}

function initMariaDB() {
  echo "Installing MariaDB..."
  doguctl state installing

  mariadb_install_db --user=mariadb --datadir="${DATABASE_VOLUME}"

  # start daemon in background
  mariadbd --user=mariadb --datadir="${DATABASE_VOLUME}" &
  pid=$!

  applySecurityConfiguration

  echo "Stopping database finishing installation..."
  kill "${pid}"
  wait "${pid}" || true
}

function setDoguLogLevel() {
  currentLogLevel=$(doguctl config --default "ERROR" "logging/root")

  case "${currentLogLevel}" in
    "WARN")
      DOGU_LOGLEVEL=2
    ;;
    "INFO")
      DOGU_LOGLEVEL=3
    ;;
    "DEBUG")
      DOGU_LOGLEVEL=9
    ;;
    *)
      DOGU_LOGLEVEL=1
    ;;
  esac
}

function renderConfigFile() {
  echo "Rendering config file..."

  INNODB_BUFFER_POOL_SIZE_IN_BYTES="$(calculateInnoDbBufferPoolSize)"
  export INNODB_BUFFER_POOL_SIZE_IN_BYTES
  echo "Setting innodb_buffer_pool_size to ${INNODB_BUFFER_POOL_SIZE_IN_BYTES} bytes"

  doguctl template "${STARTUP_DIR}/default-config.cnf.tpl" "${DATABASE_CONFIG_DIR}/default-config.cnf"
}

function calculateInnoDbBufferPoolSize() {
  defaultInnoDbBufferPool512M="512M"
  memoryLimitFromEtcd=$(doguctl config "container_config/memory_limit" -d "empty")
  if [[ "${memoryLimitFromEtcd}" == "empty" ]]; then
      echo "${defaultInnoDbBufferPool512M}"
      return
  fi

  local memoryLimitExitCode=0
  memoryLimitInBytes=$(cat < "${CONTAINER_MEMORY_LIMIT_FILE}" | tr -d '\n') || memoryLimitExitCode=$?
  if [[ memoryLimitExitCode -ne 0 ]]; then
    logError "Error while receiving container memory limit: Exit code: ${memoryLimitExitCode}. Falling back to ${defaultInnoDbBufferPool512M} MB."

    echo "${defaultInnoDbBufferPool512M}"
    return
  fi

  if ! [[ ${memoryLimitInBytes} =~ ^[0-9]+$ ]] ; then
    logError "Memory limit file does not contain a number (found: ${memoryLimitInBytes}). Falling back to ${defaultInnoDbBufferPool512M} MB."

    echo "${defaultInnoDbBufferPool512M}"
    return
  fi

  if [[ ${memoryLimitInBytes} -lt 536870912 ]]; then
    echo "${defaultInnoDbBufferPool512M}"
    return
  fi

  if [[ ${memoryLimitInBytes} -gt 549755813888 ]]; then
    logError "Detected a memory limit of > 512 GB! Was 'memory_limit' set without re-creating the container?"
  fi

  innoDbBufferPool80percent=$(echo "${memoryLimitInBytes} * 80 / 100" | bc) || memoryLimitExitCode=$?
  if [[ memoryLimitExitCode -ne 0 ]]; then
    logError "Error while calculating memory limit: Exit code: ${memoryLimitExitCode}. Falling back to ${defaultInnoDbBufferPool512M} MB."

    echo "${defaultInnoDbBufferPool512M}"
    return
  fi

  echo "${innoDbBufferPool80percent}"
  return
}

function logError() {
  errMsg="${1}"

  >&2 echo "ERROR: ${errMsg}"
}

function regularMariaDBStart() {
  setDoguLogLevel

  doguctl state ready
  mariadbd --user=mariadb --datadir="${DATABASE_VOLUME}" --log-warnings="${DOGU_LOGLEVEL}"
}

function applySecurityConfiguration() {
  echo "Applying security configuration..."
  # create random root password
  MARIADB_ROOT_PASSWORD=$(doguctl random)

  # wait until mariadb is ready to accept connections
  doguctl wait --port 3306

  # set generated root password (and do not save it in the etcd either for added security - we do not need root actually)
  mariadb -umariadb -e "GRANT ALL PRIVILEGES ON *.* TO root@'%' IDENTIFIED BY \"${MARIADB_ROOT_PASSWORD}\" WITH GRANT OPTION;"
  # remove remote root
  mariadb -umariadb -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"

  # secure the installation
  # https://github.com/twitter-forks/mysql/blob/master/scripts/mysql_secure_installation.sh
  mariadb -umariadb -e "DROP DATABASE test;"
  mariadb -umariadb -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"

  # remove anonymous user
  mariadb -umariadb -e "DELETE FROM mysql.user WHERE User='';"

  # reload privilege tables
  mariadb -umariadb -e "FLUSH PRIVILEGES;"
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  runMain
fi
