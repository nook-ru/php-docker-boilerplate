#!/usr/bin/env bash

set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'time command' and other functions
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value

source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.config.sh"

logMsg "Starting files backup..."

mkdir -p -- "${BACKUP_DIR}"

tar --exclude-from "${SCRIPT_DIR}/backup-files-excluded" -zcf "${BACKUP_DIR}/files.tgz" -C "${CODE_DIR}" .

logMsg "Finished"
