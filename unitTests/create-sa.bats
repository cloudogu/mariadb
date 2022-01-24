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
  export rake
  doguctl="$(mock_create)"
  export bundle
  export PATH="${PATH}:${BATS_TMPDIR}"
  ln -s "${rake}" "${BATS_TMPDIR}/mariadb"
  ln -s "${bundle}" "${BATS_TMPDIR}/doguctl"
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

  run /workspace/resources/create-sa.sh

  assert_success
  assert_line "user"
  assert_line "password"
  assert_line "database"
  assert_equal "$(mock_get_call_num "${mariadb}")" "1"
  assert_equal "$(mock_get_call_args "${mariadb}" "1")" "something"
  assert_equal "$(mock_get_call_num "${doguctl}")" "1"
  assert_equal "$(mock_get_call_args "${doguctl}" "1")" "something"
}
