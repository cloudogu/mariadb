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
  echo ""
}

teardown() {
  echo ""
}

@test "upgrade-notification.sh should run without error" {
  run /workspace/resources/upgrade-notification.sh 1.2.3-4 2.3.4-5

  assert_success
}

@test "upgrade-notification.sh should fail for 1 missing argument" {
  run /workspace/resources/upgrade-notification.sh 1.2.3-4

  assert_failure
}

@test "upgrade-notification.sh should fail for 2 missing arguments" {
  run /workspace/resources/upgrade-notification.sh

  assert_failure
}
