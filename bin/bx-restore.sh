#!/usr/bin/env bash

# @todo переписать на php для портируемости на винду (заменить на composer create-project, см. https://github.com/symfony/symfony-installer#creating-symfony-4-projects)
# @todo для БД в utf-8 неправильно прописывается кодировка в /bitrix/php_interface/after_connect*.php
# @todo Брать настройки из опцией командной строки или config-файла

set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'time command' and other functions
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value

source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.config.sh"

if [ -z "$1" ]
  then
  	printf "\nUsage:\n"
  	printf "\t$(basename $0) <backup_url or backup file>\n\n"
    printf "Please supply backup url as an argument\n\n"
    exit 1
fi

backupUrl=$1
documentRoot="${CODE_DIR}"
backupName=$(basename ${backupUrl})

mkdir -p -- "${BACKUP_DIR}"

# имя БД создается из имени папки сайта, все символы кроме латинских букв и цифр заменяются на знак подчеркивания. последний сегмент заменяется на `_db`
databaseHost="mysql"
databaseName="database"
databaseUser="dev"
databasePassword="dev"

function isValidUrl() {

  if curl --output /dev/null --silent --head --fail "$1"; then
    echo "true"
  else
    echo "false"
  fi

}

function writeDbConfig() {

  logMsg "Writing db config…"

  # @todo Update after_connect_d7.php if exists
  #if [ -f "${documentRoot}/bitrix/php_interface/after_connect_d7.php" ]; then
    #sed -i "s@utf8@utf8mb4@g" ${documentRoot}/bitrix/php_interface/after_connect_d7.php
  #fi

  # @todo Update after_connect.php if exists
  #if [ -f "${documentRoot}/bitrix/php_interface/after_connect.php" ]; then
    #sed -i "s@utf8@utf8mb4@g" ${documentRoot}/bitrix/php_interface/after_connect.php
  #fi

  # @todo add escape for password
  if [ -f "${documentRoot}/bitrix/php_interface/dbconn.php" ]; then
    sed -i -E "s|\\\$DBHost.+|\\\$DBHost = \"${databaseHost}\";|g" ${documentRoot}/bitrix/php_interface/dbconn.php \
      && sed -i -E "s|\\\$DBName.+|\\\$DBName = \"${databaseName}\";|g" ${documentRoot}/bitrix/php_interface/dbconn.php \
      && sed -i -E "s|\\\$DBLogin.+|\\\$DBLogin = \"${databaseUser}\";|g" ${documentRoot}/bitrix/php_interface/dbconn.php \
      && sed -i -E "s|\\\$DBPassword.+|\\\$DBPassword = \"${databasePassword}\";|g" ${documentRoot}/bitrix/php_interface/dbconn.php

    # Switch on MySQLi
    if ! (( $(grep -wc "BX_USE_MYSQLI" "${documentRoot}/bitrix/php_interface/dbconn.php") > 0 )); then
      sed -i "s@<?@<?php\ndefine(\"BX_USE_MYSQLI\", true);\n?><?@1" ${documentRoot}/bitrix/php_interface/dbconn.php
    fi
  fi

  if [ -f "${documentRoot}/bitrix/.settings.php" ]; then
  	# wtf is docker?
    sed -i "s@//#docker@@g" ${documentRoot}/bitrix/.settings.php \
      && sed -i -E "s@'host' =>.+,@'host' => '${databaseHost}',@g" ${documentRoot}/bitrix/.settings.php \
      && sed -i -E "s@'database' =>.+,@'database' => '${databaseName}',@g" ${documentRoot}/bitrix/.settings.php \
      && sed -i -E "s@'login' =>.+,@'login' => '${databaseUser}',@g" ${documentRoot}/bitrix/.settings.php \
      && sed -i -E "s@'password' =>.+,@'password' => '${databasePassword}',@g" ${documentRoot}/bitrix/.settings.php \

    # Switch on MySQLi
    sed -i -E "s@MysqlConnection@MysqliConnection@g" ${documentRoot}/bitrix/.settings.php
  fi

}

function dropDb(){

  MYSQL_ROOT_PASSWORD=$(dockerExecMySQL printenv MYSQL_ROOT_PASSWORD)

  logMsg "Dropping ${databaseName}…"

  echo "DROP DATABASE IF EXISTS \`${databaseName}\`;" | dockerExecMySQL sh -c "MYSQL_PWD=\"${MYSQL_ROOT_PASSWORD}\" mysql -h mysql -uroot"

}

function importDb(){
  MYSQL_ROOT_PASSWORD=$(dockerExecMySQL printenv MYSQL_ROOT_PASSWORD)

  local backupNameWithoutExt=`basename ${backupName} .tar.gz`
  local backupPrefix=${documentRoot}/bitrix/backup/${backupNameWithoutExt}

  logMsg "Restoring ${databaseName}…"

  echo "CREATE DATABASE IF NOT EXISTS \`${databaseName}\`;" | dockerExecMySQL sh -c "MYSQL_PWD=\"${MYSQL_ROOT_PASSWORD}\" mysql -h mysql -uroot"

  ( awk '{gsub("<DATABASE>", "'${databaseName}'", $0); print}' ${backupPrefix}_after_connect.sql; cat ${backupPrefix}.sql ) | dockerExecMySQL sh -c "MYSQL_PWD=\"${MYSQL_ROOT_PASSWORD}\" mysql -h mysql -uroot ${databaseName}"

  echo "FLUSH PRIVILEGES;" | dockerExecMySQL sh -c "MYSQL_PWD=\"${MYSQL_ROOT_PASSWORD}\" mysql -h mysql -uroot"

  # Delete sensitive SQL data
  if [ -f "${backupPrefix}.sql" ]; then
    rm -f ${backupPrefix}.sql
  fi

  if [ -f "${backupPrefix}_after_connect.sql" ]; then
    rm -f ${backupPrefix}_after_connect.sql
  fi

}

function downloadBackup() {

  local validUrl=$(isValidUrl "${backupUrl}")

  if [ "${validUrl}" = "true" ]; then

    logMsg "Downloading…"

    local counter=0

    # Download
    while [ "${validUrl}" = "true" ]
    do
      currentUrl="${backupUrl}"
      if (( ${counter} > 0 )); then
        currentUrl+=".${counter}"
      fi

      validUrl=$(isValidUrl "${currentUrl}")
      if [ "${validUrl}" = true ]; then
        wget -nv "${currentUrl}" -P "${BACKUP_DIR}"
      fi

      let counter=counter+1
    done
  else

    logMsg "Using local backup file ${backupUrl}"

  fi

}

function extractFiles() {

  logMsg "Extracting…"

  if [ $(isValidUrl "${backupUrl}") = true ]; then
    cat "${BACKUP_DIR}/${backupName}*" | tar xz -C "$CODE_DIR"
  else
    cat ${backupUrl}* | tar xz -C "$CODE_DIR"
  fi

  # удаляем только если скачивали бекап
  #if [ $(isValidUrl "${backupUrl}") = true ]; then
  #  removeBackup
  #fi

}

function removeBackup() {

  logMsg "Removing backup files…"
  rm ./${backupName}*

}

function cleanupCode() {

  if [ ! -d "$CODE_DIR" ]; then

    logMsg "Cleaning up…"

    cd "${CODE_DIR}"

    shopt -s extglob
    set +e
    rm -Rf -- "!(.|..|.idea|.git)"
    set -e
    shopt -u extglob

    cd -

  fi

}

function backupCode() {

  #if app dir exists then backup it with timestamp
  [ ! -d "$CODE_DIR" ] || mv "$CODE_DIR" "$CODE_DIR".$(date +%Y%m%d%H%M%S);

  mkdir -p -- "$CODE_DIR/"
  chmod 755 "$CODE_DIR/"

}

backupCode
#cleanupCode todo
downloadBackup
extractFiles
writeDbConfig
dropDb
importDb

logMsg "Done!"
