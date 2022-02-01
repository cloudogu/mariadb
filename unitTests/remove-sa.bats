#! /bin/bash
# Bind an unbound BATS variables that fail all tests when combined with 'set -o nounset'
export BATS_TEST_START_TIME="0"
export BATSLIB_FILE_PATH_REM=""
export BATSLIB_FILE_PATH_ADD=""

load '/workspace/target/bats_libs/bats-support/load.bash'
load '/workspace/target/bats_libs/bats-assert/load.bash'
load '/workspace/target/bats_libs/bats-mock/load.bash'
load '/workspace/target/bats_libs/bats-file/load.bash'

GENERIC_DOGU_NAME="mydogu"

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

@test "remove-sa.sh should print the credentials" {
  mock_set_status "${mariadb}" 0
  mock_set_status "${doguctl}" 0
  mock_set_output "${mariadb}" "mydogu_12345678" 1
  mock_set_output "${mariadb}" "dontCare" 2

  run /workspace/resources/remove-sa.sh mydogu

  assert_success
  assert_line "Deleting service account 'mydogu_12345678'"
  assert_equal "$(mock_get_call_num "${mariadb}")" "4"

  assert_equal "$(mock_get_call_args "${mariadb}" "1")" "-umariadb -B --disable-column-names -e SHOW DATABASES like 'mydogu\_%'"
  assert_equal "$(mock_get_call_args "${mariadb}" "2")" '-umariadb -e DROP DATABASE if exists mydogu_12345678;'
  assert_equal "$(mock_get_call_args "${mariadb}" "3")" '-umariadb -e DROP USER if exists mydogu_12345678;'
  assert_equal "$(mock_get_call_args "${mariadb}" "4")" '-umariadb -e FLUSH PRIVILEGES;'
  assert_equal "$(mock_get_call_num "${doguctl}")" "0"
}

@test "remove-sa.sh should fail for missing dogu argument" {
  mock_set_status "${mariadb}" 0
  mock_set_status "${doguctl}" 0

  mock_set_output "${doguctl}" "rndDbName" 1
  mock_set_output "${doguctl}" "s3cR37p455w0rD" 2

  run /workspace/resources/remove-sa.sh

  assert_failure
  assert_line  'usage remove-sa.sh servicename'
  assert_equal "$(mock_get_call_num "${mariadb}")" "0"
  assert_equal "$(mock_get_call_num "${doguctl}")" "0"
}
