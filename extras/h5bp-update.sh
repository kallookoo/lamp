#!/usr/bin/env bash

#
# Update the h5bp files from the git repository if exists
#

LAMP_PATH="$(cd -P -- "$(dirname -- "$(dirname -- "$0")")" && pwd -P)"
H5BP_SRC="$(sed -r 's@/lamp@@' <<< "$LAMP_PATH")/server-configs-apache/h5bp"
if [ -d "$H5BP_SRC" ]
then
  # Use subshell to hidden all outputs.
  LAST_COMMIT="$(cd "$H5BP_SRC" && git pull -f origin main >/dev/null 2>&1 && git rev-parse HEAD)"

  DISTROS=(
    "debian"
  )

  for DISTRO in "${DISTROS[@]}"
  do
    if [ -d "${LAMP_PATH}/${DISTRO}/apache/h5bp" ]
    then
      if [ -n "$LAST_COMMIT" ] && [ -f "${LAMP_PATH}/${DISTRO}/apache/h5bp.conf" ]
      then
        sed -i "s/H5BP_COMMIT.*/H5BP_COMMIT: ${LAST_COMMIT}/" "${LAMP_PATH}/${DISTRO}/apache/h5bp.conf"
      fi
      find "${LAMP_PATH}/${DISTRO}/apache/h5bp" -mindepth 1 -type f | \
        while read -r H5BP_LAMP_FILE
        do
          H5BP_SRC_FILE="${H5BP_SRC}/$(sed -r 's@/.*h5bp/@@' <<< "${H5BP_LAMP_FILE}")"
          if [ -f "${H5BP_SRC_FILE}" ]
          then
            cp -f "${H5BP_SRC_FILE}" "${H5BP_LAMP_FILE}"
          fi
        done
    fi
  done
fi
