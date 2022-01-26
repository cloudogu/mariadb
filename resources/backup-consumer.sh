#!/bin/bash

# this exposed-command can be used to backup dogu databases stored in MariaDB.

set -o errexit
set -o pipefail

# read service account keys from stdin
while read -r line; do
  case $line in
  database:*)
  database_name=${line//database: /};;
  esac
done

# continue when all service-account keys are provided
if [[ -n ${database_name} ]]; then

  # print database dump on StdOut
  mariadb_dump "${database_name}"

else
  echo "Please provide following service-account keys: database" >&2;
  exit 1;
fi

