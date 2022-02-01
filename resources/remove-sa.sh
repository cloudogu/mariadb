#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

SERVICE="${1:-}"
if [ X"${SERVICE}" = X"" ]; then
    echo "usage remove-sa.sh servicename"
    exit 1
fi

schemaBeingRemoved="SHOW DATABASES like '${SERVICE}\_%'"

for database_name in $(mariadb -umariadb -B --disable-column-names -e "${schemaBeingRemoved}")
do
  echo "Deleting service account '${database_name}'"
  mariadb -umariadb -e "DROP DATABASE if exists ${database_name};" >/dev/null 2>&1
  mariadb -umariadb -e "DROP USER if exists ${database_name};" >/dev/null 2>&1
  mariadb -umariadb -e "FLUSH PRIVILEGES;" >/dev/null 2>&1
done
