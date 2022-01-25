#! /bin/bash
# Bind an unbound BATS variables that fail all tests when combined with 'set -o nounset'
export BATS_TEST_START_TIME="0"
export BATSLIB_FILE_PATH_REM=""
export BATSLIB_FILE_PATH_ADD=""

load '/workspace/target/bats_libs/bats-support/load.bash'
load '/workspace/target/bats_libs/bats-assert/load.bash'
load '/workspace/target/bats_libs/bats-mock/load.bash'
load '/workspace/target/bats_libs/bats-file/load.bash'


setup() {
  export STARTUP_DIR=/workspace/resources
  export WORKDIR=/workspace
  doguctl="$(mock_create)"
  mysql_install_db="$(mock_create)"
  mysqld_safe="$(mock_create)"
  mariadb="$(mock_create)"

  export PATH="${PATH}:${BATS_TMPDIR}"
  ln -s "${doguctl}" "${BATS_TMPDIR}/doguctl"
  ln -s "${mysql_install_db}" "${BATS_TMPDIR}/mysql_install_db"
  ln -s "${mysqld_safe}" "${BATS_TMPDIR}/mysqld_safe"
  ln -s "${mariadb}" "${BATS_TMPDIR}/mariadb"
}

teardown() {
  unset STARTUP_DIR
  unset WORKDIR
  rm "${BATS_TMPDIR}/mysql_install_db"
  rm "${BATS_TMPDIR}/doguctl"
  rm "${BATS_TMPDIR}/mysqld_safe"
  rm "${BATS_TMPDIR}/mariadb"
}

@test "startup with existing db should only start mariadb" {
  # shellcheck source=/workspace/resources/startup.sh
  source "${STARTUP_DIR}/startup.sh"

  mock_set_status "${mysqld_safe}" 0
  mock_set_status "${doguctl}" 0

  DATABASE_STORAGE="$(mktemp)"
  export DATABASE_STORAGE

  run runMain

  assert_success
  assert_equal "$(mock_get_call_args "${mysqld_safe}" "1")" "--user=mysql"
  assert_equal "$(mock_get_call_args "${doguctl}" "1")" "state ready"
  assert_equal "$(mock_get_call_num "${mysqld_safe}")" "1"
  assert_equal "$(mock_get_call_num "${doguctl}")" "1"
}

@test "initMariaDB" {
  # shellcheck source=/workspace/resources/startup.sh
  source "${STARTUP_DIR}/startup.sh"

  mock_set_status "${doguctl}" 0
  mock_set_status "${mysql_install_db}" 0
  mock_set_status "${mysqld_safe}" 0

  function applySecurityConfiguration () {
   echo ""
  }

  run initMariaDB

  assert_success
  assert_equal "$(mock_get_call_args "${doguctl}" "1")" "state installing"
  assert_equal "$(mock_get_call_args "${mysql_install_db}" "1")" "--user=mysql --datadir=/var/lib/mysql"

  # Mock mysqld_safe will not get tested because of the execution in the background
  assert_equal "$(mock_get_call_num "${doguctl}")" "1"
}

@test "applySecurityConfiguration" {
  # shellcheck source=/workspace/resources/startup.sh
  source "${STARTUP_DIR}/startup.sh"

  mock_set_status "${doguctl}" 0
  mock_set_status "${mariadb}" 0

  password="password"
  mock_set_output "${doguctl}" "${password}" 1

  run applySecurityConfiguration

  assert_success
  assert_equal "$(mock_get_call_args "${doguctl}" "1")" "random"
  assert_equal "$(mock_get_call_args "${doguctl}" "2")" "config -e password password"
  assert_equal "$(mock_get_call_args "${doguctl}" "3")" "wait --port 3306"
  assert_equal "$(mock_get_call_args "${mariadb}" "1")" "-umysql -e GRANT ALL PRIVILEGES ON *.* TO root@'%' IDENTIFIED BY \"${password}\" WITH GRANT OPTION;"
  assert_equal "$(mock_get_call_args "${mariadb}" "2")" "-umysql -e DROP DATABASE test;"
  assert_equal "$(mock_get_call_args "${mariadb}" "3")" "-umysql -e DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%'"
  assert_equal "$(mock_get_call_args "${mariadb}" "4")" "-umysql -e DELETE FROM mysql.user WHERE User=\";\""
  assert_equal "$(mock_get_call_args "${mariadb}" "5")" "-umysql -e DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
  assert_equal "$(mock_get_call_args "${mariadb}" "6")" "-umysql -e FLUSH PRIVILEGES;"
  assert_equal "$(mock_get_call_num "${doguctl}")" "3"
  assert_equal "$(mock_get_call_num "${mariadb}")" "6"
}


