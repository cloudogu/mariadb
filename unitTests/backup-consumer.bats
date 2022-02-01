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
  mariadb_dump="$(mock_create)"
  export mariadb_dump
  export bundle
  export PATH="${PATH}:${BATS_TMPDIR}"
  ln -s "${mariadb_dump}" "${BATS_TMPDIR}/mariadb_dump"
}

teardown() {
  unset STARTUP_DIR
  unset WORKDIR
  rm "${BATS_TMPDIR}/mariadb_dump"
}

@test "backup-consumer.sh should accept database and dump data" {
  mock_set_status "${mariadb_dump}" 0
  mock_set_output "${mariadb_dump}" "DATA GOES HERE HURRAY" 1

  doguServiceAccountData=$(cat <<'END_HEREDOC'
username: redmine_123456
database: redmine_567890
password: s3cr37p455w0rD
END_HEREDOC
)

  run /workspace/resources/backup-consumer.sh <<< "${doguServiceAccountData}"

  assert_success
  # favour assert_line over assert_output here because Jenkins creates weird output over a non existing ID
  assert_line "DATA GOES HERE HURRAY"
  assert_equal "$(mock_get_call_num "${mariadb_dump}")" "1"
  assert_equal "$(mock_get_call_args "${mariadb_dump}" "1")" "redmine_567890"
}

@test "backup-consumer.sh should fail for missing dogu argument" {
  mock_set_status "${mariadb_dump}" 0

  run /workspace/resources/backup-consumer.sh

  assert_failure
  assert_output  'Please provide following service-account keys: database'
  assert_equal "$(mock_get_call_num "${mariadb_dump}")" "0"
}
