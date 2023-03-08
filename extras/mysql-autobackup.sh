#!/usr/bin/env bash

if [[ "$(id -u)" -ne "0" ]]; then
  echo "Please, run this with the root user or sudo."
  exit 1
fi

MYSQL_DIRECTORY="${1:-}"
if [ -z "$MYSQL_DIRECTORY" ]; then
  echo "Undefined directory arguments"
  echo "Usage: mysql-autobackup.sh directory"
  exit 1
fi
#shellcheck disable=SC2001
MYSQL_DIRECTORY="$(echo "$MYSQL_DIRECTORY" | sed -e 's@/$@@')"
if [ ! -d "$MYSQL_DIRECTORY" ]; then
  mkdir -p "$MYSQL_DIRECTORY"
fi

# Usage: in_array "string" "${array[@]}"
function in_array() {
  [ "$(printf '%s\n' "${@}" | grep -cx -- "${1}")" -gt "1" ] && return 0
  return 1
}

MYSQL_EXCLUDE_DATABASES=(
  information_schema
  mysql
  performance_schema
  phpmyadmin
  sys
)

for database in $(mysql -se 'show databases;' | grep -v 'Database'); do
  if in_array "$database" "${MYSQL_EXCLUDE_DATABASES[@]}"; then
    continue
  elif [ -f "$MYSQL_DIRECTORY/$database.sql" ]; then
    gzip -fk9 "$MYSQL_DIRECTORY/$database.sql"
  fi
  mysqldump --databases "$database" > "$MYSQL_DIRECTORY/$database.sql"
done
