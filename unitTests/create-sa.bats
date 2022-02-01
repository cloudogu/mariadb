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
  mariadb="$(mock_create)"
  export mariadb
  doguctl="$(mock_create)"
  export bundle
  export PATH="${PATH}:${BATS_TMPDIR}"
  ln -s "${mariadb}" "${BATS_TMPDIR}/mariadb"
  ln -s "${doguctl}" "${BATS_TMPDIR}/doguctl"
}

teardown() {
  unset STARTUP_DIR
  unset WORKDIR
  rm "${BATS_TMPDIR}/mariadb"
  rm "${BATS_TMPDIR}/doguctl"
}

@test "create-sa.sh should print the credentials" {
  mock_set_status "${mariadb}" 0
  mock_set_status "${doguctl}" 0

  mock_set_output "${doguctl}" "rndDbName" 1
  mock_set_output "${doguctl}" "s3cR37p455w0rD" 2

  run /workspace/resources/create-sa.sh mydogu

  assert_success
  assert_equal "${#lines[@]}" 3
  assert_equal "${lines[0]}" 'database: mydogu_rndDbName'
  assert_equal "${lines[1]}" 'username: mydogu_rndDbName'
  assert_equal "${lines[2]}" 'password: s3cR37p455w0rD'
  assert_equal "$(mock_get_call_num "${mariadb}")" "3"
  assert_equal "$(mock_get_call_args "${mariadb}" "1")" "-umariadb -e CREATE DATABASE mydogu_rndDbName DEFAULT CHARACTER SET utf8mb4 DEFAULT COLLATE utf8mb4_unicode_ci;"
  assert_equal "$(mock_get_call_args "${mariadb}" "2")" '-umariadb -e grant all on mydogu_rndDbName.* to "mydogu_rndDbName"@"%" identified by "s3cR37p455w0rD";'
  assert_equal "$(mock_get_call_args "${mariadb}" "3")" "-umariadb -e FLUSH PRIVILEGES;"
  assert_equal "$(mock_get_call_num "${doguctl}")" "2"
  assert_equal "$(mock_get_call_args "${doguctl}" "1")" "random -l 6"
  assert_equal "$(mock_get_call_args "${doguctl}" "2")" "random"
}

@test "create-sa.sh should fail for missing dogu argument" {
  mock_set_status "${mariadb}" 0
  mock_set_status "${doguctl}" 0

  mock_set_output "${doguctl}" "rndDbName" 1
  mock_set_output "${doguctl}" "s3cR37p455w0rD" 2

  run /workspace/resources/create-sa.sh

  assert_failure
  assert_line  'usage create-sa.sh servicename'
  assert_equal "$(mock_get_call_num "${mariadb}")" "0"
  assert_equal "$(mock_get_call_num "${doguctl}")" "0"
}
