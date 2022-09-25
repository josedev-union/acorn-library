#!/bin/bash
export MONGODB_DAEMON_USER="mongodb"
export MONGODB_DAEMON_GROUP="mongodb"
export MONGODB_BASE_DIR="/"
export MONGODB_DATA_DIR="/var/lib/mongodb"
export MONGODB_CONF_DIR="/var/lib/mongodb"
export MONGODB_TMP_DIR="$MONGODB_BASE_DIR/tmp"
export MONGODB_CONF_FILE="$MONGODB_CONF_DIR/mongodb.conf"
export MONGODB_MOUNTED_CONF_DIR="${MONGODB_MOUNTED_CONF_DIR:-/etc/mongo/}"
export MONGODB_PID_FILE="$MONGODB_TMP_DIR/mongodb.pid"
export MONGODB_MAX_TIMEOUT="${MONGODB_MAX_TIMEOUT:-35}"
export MONGODB_KEY_FILE="$MONGODB_CONF_DIR/keyfile"
export MONGODB_DEFAULT_PORT_NUMBER="27017"
export MONGODB_PORT_NUMBER="${MONGODB_PORT_NUMBER:-$MONGODB_DEFAULT_PORT_NUMBER}"
MONGODB_SHELL_EXTRA_FLAGS="${MONGODB_SHELL_EXTRA_FLAGS:-"${MONGODB_CLIENT_EXTRA_FLAGS:-}"}"
export MONGODB_ADVERTISE_IP="${MONGODB_ADVERTISE_IP:-false}"
export MONGODB_REPLICA_SET_MODE="${MONGODB_REPLICA_SET_MODE:-}"
export MONGODB_BIN_DIR=/usr/bin/
export MONGODB_ADVERTISED_HOSTNAME="${MONGODB_ADVERTISED_HOSTNAME:-}"
export MONGODB_ADVERTISED_PORT_NUMBER="${MONGODB_ADVERTISED_PORT_NUMBER:-}"

export ACORN_DEBUG=true