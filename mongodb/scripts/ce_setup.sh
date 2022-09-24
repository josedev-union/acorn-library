#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purposes
. /acorn/scripts/ce_utils.sh
. /acorn/scripts/ce_mongo_utils.sh
. /acorn/scripts/env.sh

print_image_welcome_page
############################################################################### setup
info "** Starting MongoDB setup **"

# Ensure MongoDB env var settings are valid
# validation
# 1. replica set authentication (arch=rs, auth_enabled=true)
#  - replica_set_key should be non-empty
#  - MONGODB_ROOT_PASSWORD(primary), MONGODB_INITIAL_PRIMARY_ROOT_PASSWORD(secondary)

# Ensure MongoDB is stopped when this script ends.
trap "mongodb_stop" EXIT

# Ensure 'daemon' user exists when running as 'root'
export MONGODB_DAEMON_USER="mongo"
export MONGODB_DAEMON_GROUP="mongo"
# am_i_root && ensure_user_exists "$MONGODB_DAEMON_USER" --group "$MONGODB_DAEMON_GROUP"
# Fix logging issue when running as root
am_i_root && chmod o+w "$(readlink /dev/stdout)"

# Ensure directories used by MongoDB exist and have proper ownership and permissions
# for dir in "$MONGODB_TMP_DIR" "$MONGODB_LOG_DIR" "$MONGODB_DATA_DIR"; do
#     ensure_dir_exists "$dir"
#     am_i_root && chown -R "${MONGODB_DAEMON_USER}:${MONGODB_DAEMON_GROUP}" "$dir"
# done

# Ensure MongoDB is initialized
mongodb_initialize

mongodb_set_listen_all_conf

info "** MongoDB setup finished! **"
