#!/bin/bash
set -ex
BACKUP_NAME_PREFIX=mongodbdump
ARCHIVE_NAME="${BACKUP_NAME_PREFIX}.$(date +%Y%m%d-%H%M%S).gz"
BACKUP_DIR='/backups'

mkdir -p ${BACKUP_DIR}

if [ -f "${BACKUP_DIR}/restore_in_progress" ]; then
   echo "Restore in progress... exiting"
   exit 0
fi


#Log message to a file or stdout
#Params: $1 log level
#Params: $2 service
#Params: $3 message
#Params: $4 Destination
log() {
    LEVEL=$1
    SERVICE=$2
    MSG=$3
    DEST=$4
    DATE=$(date +"%m-%d-%y %H:%M:%S")
    if [[ -z "$DEST" ]]; then
        echo "${DATE} ${LEVEL}: $(hostname) ${SERVICE}: ${MSG}"
    else
        echo "${DATE} ${LEVEL}: $(hostname) ${SERVICE}: ${MSG}" >>$DEST
    fi
}

# get_archive_date function returns correct archive date
function get_archive_date(){
    local A_FILE="$1"
    awk -F. '{print $(NF-2)}' <<< ${A_FILE} | tr -d "Z"
}

# This function takes a list of archives' names as an input
# and creates a hash table where keys are number of seconds
# between current date and archive date (see seconds_difference),
# and values are space separated archives' names
#
# +------------+---------------------------------------------------------------------------------------------------------+
# | 1265342678 | "/backups/mongodbdump.20220214-101313.tar.gz"                                                           |
# +------------+---------------------------------------------------------------------------------------------------------+
# | 2346254257 | "/backups/mongodbdump.20220211-101313.tar.gz                                                            |
# +------------+---------------------------------------------------------------------------------------------------------+
# <...>
# +------------+---------------------------------------------------------------------------------------------------------+
# | 6253434567 | "/backups/mongodbdump.20220201101313.tar.gz"                                                            |
# +------------+---------------------------------------------------------------------------------------------------------+
# We will use the explained above data stracture to cover rare, but still
# possible case, when we have several backups of the same date. E.g.
# one manual, and one automatic.
declare -A fileTable
create_hash_table() {
unset fileTable
fileList=$@
    for ARCHIVE_FILE in ${fileList}; do
        # Creating index, we will round given ARCHIVE_DATE to the midnight (00:00:00)
        # to take in account a possibility, that we can have more than one scheduled
        # backup per day.
        ARCHIVE_DATE=$(get_archive_date ${ARCHIVE_FILE})
        ARCHIVE_DATE=$(date --date=${ARCHIVE_DATE} +%D)
        log INFO "mongodb_backup" "Archive date to build index: ${ARCHIVE_DATE}"
        INDEX=$(seconds_difference ${ARCHIVE_DATE})
        if [[ -z fileTable[${INDEX}] ]]; then
            fileTable[${INDEX}]=${ARCHIVE_FILE}
        else
            fileTable[${INDEX}]="${fileTable[${INDEX}]} ${ARCHIVE_FILE}"
        fi
        echo "INDEX: ${INDEX} VALUE:  ${fileTable[${INDEX}]}"
    done
}

remove_old_local_archives() {
    SECONDS_TO_KEEP=$(( $((${DAYS_TO_KEEP_BACKUP}))*86400))
    log INFO "mongodb_backup" "Deleting backups older than ${DAYS_TO_KEEP_BACKUP} days (${SECONDS_TO_KEEP} seconds)"

    count=0
    # We iterate over the hash table, checking the delta in seconds (hash keys),
    # and minimum number of backups we must have in place. List of keys has to be sorted.
    for INDEX in $(tr " " "\n" <<< ${!fileTable[@]} | sort -n -); do
        ARCHIVE_FILE=${fileTable[${INDEX}]}
        if [[ ${INDEX} -lt ${SECONDS_TO_KEEP} || ${count} -lt ${DAYS_TO_KEEP_BACKUP} ]]; then
            ((count++))
            log INFO "mongodb_backup" "Keeping file(s) ${ARCHIVE_FILE}."
        else
            log INFO "mongodb_backup" "Deleting file(s) ${ARCHIVE_FILE}."
            rm -f ${ARCHIVE_FILE}
            if [[ $? -ne 0 ]]; then
                # Log error but don't exit so we can finish the script
                # because at this point we haven't sent backup to RGW yet
                log ERROR "mongodb_backup" "Failed to cleanup old backup. Cannot remove some of ${ARCHIVE_FILE}"
            fi
        fi
    done
}

# comparison is performed without regard to the case of alphabetic characters
shopt -s nocasematch
OPLOG_FLAG=""
if [[ "$PTR_BACKUP" = 1 || "$PTR_BACKUP" =~ ^(yes|true)$ ]]; then
    OPLOG_FLAG="--oplog"
fi

COLLECTION_OPTION=""
if [[ -z "$BACKUP_COLLECTION" ]]; then
    COLLECTION_OPTION="--collection=$BACKUP_COLLECTION"
fi

DATABASE_OPTION=""
if [[ -z "$BACKUP_DB" ]]; then
    DATABASE_OPTION="--db=$BACKUP_DB"
fi

echo "Backup in progress..."
set +x
mongodump $OPLOG_FLAG $COLLECTION_OPTION $DATABASE_OPTION \
    -u $BACKUP_USER \
    -p $BACKUP_PASSWORD \
    --authenticationDatabase admin \
	--archive="$BACKUP_DIR/$ARCHIVE_NAME" \
	--gzip \
	--uri "$MONGODB_URI"
set -x

if [[ $? -eq 0 && -s $BACKUP_DIR/$ARCHIVE_NAME ]]
then
    log INFO "Backup success."
else
    log ERROR "Backup failed and need attention."
    exit 1
fi

echo "Latest backup is $BACKUP_DIR/$ARCHIVE_NAME"

cd $BACKUP_DIR
#Only delete the old archive after a successful backup
export DAYS_TO_KEEP_BACKUP=$(echo $DAYS_TO_KEEP_BACKUP | sed 's/"//g')
if [[ "$DAYS_TO_KEEP_BACKUP" -gt 0 ]]; then
    create_hash_table $(ls -1 ${BACKUP_DIR}/BACKUP_NAME_PREFIX*.gz)
    remove_old_local_archives

fi
ls -lrt ${BACKUP_DIR}/ > /run/secrets/output