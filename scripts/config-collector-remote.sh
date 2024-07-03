#!/usr/bin/env bash

REPORT_REMOTE_DIR=/var/log/turbolab.it/
REPORT_REMOTE_FILE=${REPORT_REMOTE_DIR}multissh-config-collector.csv

mkdir -p "${REPORT_REMOTE_DIR}"
>${REPORT_REMOTE_FILE}

function addToReport()
{
  PARAM_NAME=$1
  PARAM_VALUE=$2
  NO_PIPE=$3

  echo "$PARAM_NAME: $PARAM_VALUE"
  echo -n "$PARAM_VALUE" >> ${REPORT_REMOTE_FILE}
  if [ -z "$NO_PIPE" ]; then
    echo -n "|" >> ${REPORT_REMOTE_FILE}
  fi
}

## report date
addToReport 'coll_date' $(date +%F)

## hostname
addToReport 'hostname' $(hostname)

## Linux distribution name
REPORT_OS=$(grep '^ID=' /etc/os-release)
REPORT_OS=${REPORT_OS:3}
REPORT_OS=${REPORT_OS//\"}
addToReport 'os' "$REPORT_OS"

## Linux distribution version
REPORT_OS_VERSION=$(grep '^VERSION_ID=' /etc/os-release)
REPORT_OS_VERSION=${REPORT_OS_VERSION:11}
REPORT_OS_VERSION=${REPORT_OS_VERSION//\"}
addToReport 'os_version' "$REPORT_OS_VERSION"

## SSH version
REPORT_SSH_VERSION=$(ssh -V)
addToReport 'ssh_version' "REPORT_SSH_VERSION"

## PHP versions
REPORT_PHP_VERSION=$(ls /usr/bin/php*)
REPORT_PHP_VERSION=$(echo $REPORT_PHP_VERSION | sed -n 's/[^0-9]*\([0-9]\+\.[0-9]\+\)[^0-9]*/\1,/gp' | sed 's/,$//')
addToReport 'php_versions' "$REPORT_PHP_VERSION"

## zzfirewall
ZZFIREWALL_DIR=/usr/local/turbolab.it/zzfirewall/
if [ -d "${ZZFIREWALL_DIR}" ]; then
  REPORT_ZZFIREWALL='Y'
else
  REPORT_ZZFIREWALL='N'
fi

addToReport 'zzfirewall' $REPORT_ZZFIREWALL

## webstackup
WEBSTACKUP_DIR=/usr/local/turbolab.it/webstackup/
WEBSTACKUP_CONFIG=/etc/turbolab.it/webstackup.conf
if [ -d "${WEBSTACKUP_DIR}" ] && [ -f "${WEBSTACKUP_CONFIG}" ]; then
  REPORT_WEBSTACKUP='Y'
else
  REPORT_WEBSTACKUP='N'
fi

addToReport 'webstackup' $REPORT_WEBSTACKUP

## private generics
PRIVGEN_DIR=/var/www/private_generics/
if [ -d "${PRIVGEN_DIR}" ]; then
  REPORT_PRIV_GEN='Y'
else
  REPORT_PRIV_GEN='N'
fi

addToReport 'priv_gen' $REPORT_PRIV_GEN
