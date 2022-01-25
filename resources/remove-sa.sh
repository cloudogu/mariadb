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

for database_name in $(mariadb -umysql -B --disable-column-names -e "${schemaBeingRemoved}")
do
  echo "Deleting service account '${database_name}'"
  mariadb -umysql -e "DROP DATABASE if exists ${database_name};" >/dev/null 2>&1
  mariadb -umysql -e "DROP USER if exists ${database_name};" >/dev/null 2>&1
  mariadb -umysql -e "FLUSH PRIVILEGES;" >/dev/null 2>&1
done
