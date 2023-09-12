#!/bin/bash 

# dial tone
touch /opt/oh-no-mongo.txt

# fetch and install mongo and other accoutrements
curl -JLO https://repo.mongodb.org/apt/ubuntu/dists/focal/mongodb-org/5.0/multiverse/binary-amd64/mongodb-org-server_5.0.20_amd64.deb
curl -JLO https://repo.mongodb.org/apt/ubuntu/dists/focal/mongodb-org/5.0/multiverse/binary-amd64/mongodb-org-shell_5.0.20_amd64.deb
curl -JLO https://fastdl.mongodb.org/tools/db/mongodb-database-tools-ubuntu2004-x86_64-100.8.0.deb
dpkg -i mongodb-database-tools-ubuntu2004-x86_64-100.8.0.deb
dpkg -i mongodb-org-server_5.0.20_amd64.deb
dpkg -i mongodb-org-shell_5.0.20_amd64.deb

# turn on auth and listen on all interfaces
sed -i 's/#security:/security:\n  authorization: enabled/' /etc/mongod.conf
sed -i 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/' /etc/mongod.conf
systemctl start mongod

# hack
sleep 5

# Create an admin user
mongo admin --eval "db.createUser({ user: 'admin', pwd: 'superSecret', roles: [ { role: 'root', db: 'admin' } ] })"

# Create a database and user
#mongo -u admin -p superSecret --eval "db.createCollection('app')"
#mongo app --eval "db.createUser({ user: 'app', pwd: 'appPassword', roles: ['readWrite'] })"

sudo systemctl restart mongod

# install awscli
apt-get update
apt-get install unzip
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

# configure nightly mongodb backups (2am).
# The cloud-init config drops this file for us.
echo '0  2    * * *   root    /bin/bash' > /opt/backup-mongo.sh

# run it once
./opt/backup-mongo.sh
