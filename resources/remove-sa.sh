#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

SERVICE="${1}"
if [ X"${SERVICE}" = X"" ]; then
    echo "usage remove-sa.sh servicename"
    exit 1
fi

# connection user
ADMIN_USERNAME=root

schemaBeingRemoved="SHOW DATABASES like '${SERVICE}\_%'"

for database_name in $(mysql -B --disable-column-names -u "${ADMIN_USERNAME}" -e "${schemaBeingRemoved}")
do
  echo "Deleting service account '${database_name}'"
  mysql -u "${ADMIN_USERNAME}" -e "DROP DATABASE if exists ${database_name};" >/dev/null 2>&1
  mysql -u "${ADMIN_USERNAME}" -e "DROP USER if exists ${database_name};" >/dev/null 2>&1
done
