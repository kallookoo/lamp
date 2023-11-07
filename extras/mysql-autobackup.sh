#!/usr/bin/env bash

#
# Create the compressed backups for created databases
#

if [[ "$(id -u)" -ne "0" ]]
then
  echo "Please, run this with the root user or sudo."
  exit 1
fi

if [[ -z "$1" ]]
then
  echo "Undefined directory arguments"
  echo "Usage: mysql-autobackup.sh directory"
  exit 1
fi

MYSQL_DIRECTORY="${1%*/}"
if [[ ! -d "$MYSQL_DIRECTORY" ]]
then
  mkdir -p "$MYSQL_DIRECTORY"
fi

# Usage: in_array string ${array[@]}
function in_array() {
  if [[ $# -gt 2 && "$(printf '%s\n' "${@}" | grep -cx -- "$1")" -gt "1" ]]
  then
    return 0
  fi
  return 1
}

MYSQL_COMMAND="mysqldump"
if command -v mariadb-dump >/dev/null 2>&1
then
  MYSQL_COMMAND="mariadb-dump"
fi
MYSQL_EXCLUDE_DATABASES=(
  information_schema
  mysql
  performance_schema
  phpmyadmin
  sys
)

for database in $(mariadb -sNe 'show databases;')
do
  if ! in_array "$database" "${MYSQL_EXCLUDE_DATABASES[@]}"
  then
    $MYSQL_COMMAND --databases "$database" | gzip -k9 > "$MYSQL_DIRECTORY/$database.sql.gz"
  fi
done
