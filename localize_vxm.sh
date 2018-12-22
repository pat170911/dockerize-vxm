#!/bin/bash

# the vxm ip address
ip=1.1.1.1
# the marvin project dir
path=/expansion/workspace/marvin

echo -n "enter the vxm ip address > "
read text
ip=$text

echo "backup remote database..."
echo "please enter the vxm password..."
ssh root@$ip "pg_dumpall -U postgres > ~/alldump.sql" # may have synchronization problem.

echo "scp remote files to local..."
echo "please enter the vxm password..."
scp -r root@$ip:'/var/lib/vmware-marvin/trust \
				 /etc/vmware-marvin/ssl \
				 /etc/vmware-marvin/password.key \
				 /var/lib/vmware-marvin/runtime.properties \
				 ~/alldump.sql' .

mv ./trust ./ssl password.key runtime.properties ./tomcat
mv ./alldump.sql ./psql

echo -n "enter the path of your marvin project(default: /home/mystic/workspace/marvin) > "
read text
if [ "$text" != "" ]; then
	path=$text
else
    echo "use the default path..."
fi

echo "copy pg_nba.conf from dev code..."
pg_hba="/application/mystic.manager/mystic.manager.commons/mystic.manager.commons.db/src/main/resources/conf/pg_hba.conf"
cp $path$pg_hba ./psql

echo "apple git patch to dev code..."
cp ./patch/localize-vxm.patch ./patch/dockerize-local-vxm.patch $path
OLDPWD=$PWD
cd $path
git apply localize-vxm.patch
git apply dockerize-local-vxm.patch
cd $OLDPWD

# docker container would crash when role postgres already exist.
sed -i '/CREATE ROLE postgres/ s/^/-- /' ./psql/alldump.sql
