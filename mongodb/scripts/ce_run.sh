#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purposes
. /acorn/scripts/ce_utils.sh
. /acorn/scripts/ce_mongo_lib.sh
. /acorn/scripts/env.sh

cmd=$(command -v mongod)

flags=("--config=$MONGODB_CONF_FILE")

if [[ -n "${MONGODB_EXTRA_FLAGS:-}" ]]; then
    read -r -a extra_flags <<< "$MONGODB_EXTRA_FLAGS"
    flags+=("${extra_flags[@]}")
fi

flags+=("$@")

info "** Starting MongoDB **"
if am_i_root; then
    exec gosu "$MONGODB_DAEMON_USER" "$cmd" "${flags[@]}"
else
    exec "$cmd" "${flags[@]}"
fi
