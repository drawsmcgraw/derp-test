#!/bin/bash
set -e

CREDS='-u admin -p superSecret'

# Force file syncronization and lock writes
mongo ${CREDS} admin --eval "printjson(db.fsyncLock())"

MONGODUMP_PATH="/usr/bin/mongodump"
MONGO_DATABASE="admin" #replace with your database name

TIMESTAMP=`date +%F-%H%M`
S3_BUCKET_NAME="derp-test-mongo-backup-2023" #replace with your bucket name on Amazon S3
S3_BUCKET_PATH="mongodb-backups"

# Create backup
$MONGODUMP_PATH ${CREDS} -d $MONGO_DATABASE

# Add timestamp to backup
mv dump mongodb-$HOSTNAME-$TIMESTAMP
tar cf mongodb-$HOSTNAME-$TIMESTAMP.tar mongodb-$HOSTNAME-$TIMESTAMP

# Upload to S3
aws s3 cp mongodb-$HOSTNAME-$TIMESTAMP.tar s3://$S3_BUCKET_NAME/$S3_BUCKET_PATH/mongodb-$HOSTNAME-$TIMESTAMP.tar

#Unlock database writes
mongo ${CREDS} admin --eval "printjson(db.fsyncUnlock())" 

#Delete local files
rm -rf mongodb-*