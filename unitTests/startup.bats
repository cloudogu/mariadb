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
  mariadb_install_db="$(mock_create)"
  mariadbd="$(mock_create)"
  mariadb="$(mock_create)"

  export PATH="${PATH}:${BATS_TMPDIR}"
  ln -s "${doguctl}" "${BATS_TMPDIR}/doguctl"
  ln -s "${mariadb_install_db}" "${BATS_TMPDIR}/mariadb_install_db"
  ln -s "${mariadbd}" "${BATS_TMPDIR}/mariadbd"
  ln -s "${mariadb}" "${BATS_TMPDIR}/mariadb"
}

teardown() {
  unset STARTUP_DIR
  unset WORKDIR
  rm "${BATS_TMPDIR}/mariadb_install_db"
  rm "${BATS_TMPDIR}/doguctl"
  rm "${BATS_TMPDIR}/mariadbd"
  rm "${BATS_TMPDIR}/mariadb"
}

@test "startup with existing db should only start mariadb" {
  # shellcheck source=/workspace/resources/startup.sh
  source "${STARTUP_DIR}/startup.sh"

  mock_set_status "${mariadbd}" 0
  mock_set_status "${doguctl}" 0

  DATABASE_STORAGE="$(mktemp)"
  export DATABASE_STORAGE

  run runMain

  assert_success
  assert_equal "$(mock_get_call_args "${mariadbd}" "1")" "--user=mariadb --datadir=/var/lib/mariadb --log-warnings=1"
  assert_equal "$(mock_get_call_num "${mariadbd}")" "1"
  assert_equal "$(mock_get_call_args "${doguctl}" "1")" "template /workspace/resources/default-config.cnf.tpl /workspace/resources/etc/my.cnf.d/default-config.cnf"
  assert_equal "$(mock_get_call_args "${doguctl}" "2")" "config --default ERROR logging/root"
  assert_equal "$(mock_get_call_args "${doguctl}" "3")" "state ready"
  assert_equal "$(mock_get_call_num "${doguctl}")" "3"
}

@test "initMariaDB" {
  # shellcheck source=/workspace/resources/startup.sh
  source "${STARTUP_DIR}/startup.sh"

  mock_set_status "${doguctl}" 0
  mock_set_status "${mariadb_install_db}" 0
  mock_set_status "${mariadbd}" 0

  function applySecurityConfiguration () {
   echo ""
  }

  run initMariaDB

  assert_success
  assert_equal "$(mock_get_call_args "${doguctl}" "1")" "state installing"
  assert_equal "$(mock_get_call_args "${mariadb_install_db}" "1")" "--user=mariadb --datadir=/var/lib/mariadb"

  # Mock mariadbd will not get tested because of the execution in the background
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
  assert_equal "$(mock_get_call_args "${doguctl}" "2")" "wait --port 3306"
  assert_equal "$(mock_get_call_args "${mariadb}" "1")" "-umariadb -e GRANT ALL PRIVILEGES ON *.* TO root@'%' IDENTIFIED BY \"${password}\" WITH GRANT OPTION;"
  assert_equal "$(mock_get_call_args "${mariadb}" "2")" "-umariadb -e DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
  assert_equal "$(mock_get_call_args "${mariadb}" "3")" "-umariadb -e DROP DATABASE test;"
  assert_equal "$(mock_get_call_args "${mariadb}" "4")" "-umariadb -e DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
  assert_equal "$(mock_get_call_args "${mariadb}" "5")" "-umariadb -e DELETE FROM mysql.user WHERE User='';"
  assert_equal "$(mock_get_call_args "${mariadb}" "6")" "-umariadb -e FLUSH PRIVILEGES;"

  assert_equal "$(mock_get_call_num "${doguctl}")" "2"
  assert_equal "$(mock_get_call_num "${mariadb}")" "6"
}

@test "calculateInnoDbBufferPoolSize() should return 512 MB (in bytes) if no RAM limit was set" {
  mock_set_status "${doguctl}" 0
  mock_set_output "${doguctl}" "empty" 1
  # shellcheck source=/workspace/resources/startup.sh
  source "${STARTUP_DIR}/startup.sh"

  run calculateInnoDbBufferPoolSize

  assert_success
  assert_line "512M"
  assert_equal "$(mock_get_call_args "${doguctl}" "1")" "config container_config/memory_limit -d empty"
  assert_equal "$(mock_get_call_num "${doguctl}")" "1"
}

@test "calculateInnoDbBufferPoolSize() should return 512 MB (in bytes) if RAM limit was set but is less than 512 MB" {
  mock_set_status "${doguctl}" 0
  mock_set_output "${doguctl}" "100m" 1
  # shellcheck source=/workspace/resources/startup.sh
  source "${STARTUP_DIR}/startup.sh"
  testMemoryFile="$(mktemp)"
  echo 100000000 > "${testMemoryFile}" # 100 MB
  export CONTAINER_MEMORY_LIMIT_FILE="${testMemoryFile}"

  run calculateInnoDbBufferPoolSize

  assert_success
  assert_line "512M"
  assert_equal "$(mock_get_call_args "${doguctl}" "1")" "config container_config/memory_limit -d empty"
  assert_equal "$(mock_get_call_num "${doguctl}")" "1"
}

@test "calculateInnoDbBufferPoolSize() should return 819 MB (in bytes, 80 %) if RAM limit was set to 1 GB" {
  mock_set_status "${doguctl}" 0
  mock_set_output "${doguctl}" "1g" 1

  # shellcheck source=/workspace/resources/startup.sh
  source "${STARTUP_DIR}/startup.sh"
  testMemoryFile="$(mktemp)"
  echo 1073741824 > "${testMemoryFile}" # 1024 MB
  export CONTAINER_MEMORY_LIMIT_FILE="${testMemoryFile}"

  run calculateInnoDbBufferPoolSize

  assert_success
  assert_line "858993459"
  assert_equal "$(mock_get_call_args "${doguctl}" "1")" "config container_config/memory_limit -d empty"
  assert_equal "$(mock_get_call_num "${doguctl}")" "1"
}

@test "renderConfigFile() should render default-config.cnf with 819 MB (in bytes) to the config directory" {
  mock_set_status "${doguctl}" 0
  mock_set_output "${doguctl}" "1g" 1

  mkdir -p "${STARTUP_DIR}/etc/my.cnf.d/"
  # shellcheck source=/workspace/resources/startup.sh
  source "${STARTUP_DIR}/startup.sh"
  testMemoryFile="$(mktemp)"
  echo 1073741824 > "${testMemoryFile}" # 1024 MB
  export CONTAINER_MEMORY_LIMIT_FILE="${testMemoryFile}"

  run renderConfigFile

  assert_success
  assert_file_exist "${STARTUP_DIR}/etc/my.cnf.d/default-config.cnf"
  assert_file_not_empty "${STARTUP_DIR}/etc/my.cnf.d/default-config.cnf"
  assert_equal "$(mock_get_call_args "${doguctl}" "1")" "config container_config/memory_limit -d empty"
  assert_equal "$(mock_get_call_num "${doguctl}")" "1"
}
