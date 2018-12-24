#!/bin/bash

# the vxm ip address
ip=1.1.1.1
# the marvin project dir
path=/home/mystic/workspace && marvin=/marvin

error_exit()
{
	echo "Error: $1" 1>&2
	exit 1
}

file_exist()
{
	if [ ! -f "$1" ]; then
		error_exit "file $1 doesn't exist."
	fi
}

echo -n "enter the IP of vxm > "
read text
ip=$text

ping -c 3 $ip &> /dev/null
if [ "$?" != 0 ]; then
	error_exit "host $ip not found."
fi

echo "backup remote database, enter vxm password..."
ssh root@$ip "pg_dumpall -U postgres > ~/alldump.sql" # may have synchronization problem.

echo "copy certificate files, enter vxm password..."
scp -r root@$ip:'/var/lib/vmware-marvin/trust \
				 /etc/vmware-marvin/ssl \
				 /etc/vmware-marvin/password.key \
				 /var/lib/vmware-marvin/runtime.properties \
				 ~/alldump.sql' .

cp -r ./trust ./ssl password.key runtime.properties ./tomcat && rm -rf ./trust ./ssl password.key runtime.properties
cp -r ./alldump.sql ./psql && rm -R ./alldump.sql
chmod -R 755 ./tomcat/trust ./tomcat/ssl 
chmod 644 ./tomcat/password.key ./tomcat/runtime.properties ./psql/alldump.sql

echo -n "enter the path of your marvin project(default: /home/mystic/workspace) > "
read text
if [ "$text" != "" ]; then
	path=${text%/} # strip the last slash
fi
if [ ! -d "$path" ]; then
	error_exit "$path doesn't exist."
else
	if [ ! -d "$path$marvin" ];then
		error_exit "marvin project doesn't exist in $path ."
	fi
fi

echo "copy pg_nba.conf from dev code..."
pg_hba="/marvin/application/mystic.manager/mystic.manager.commons/mystic.manager.commons.db/src/main/resources/conf/pg_hba.conf"
file_exist "$path$pg_hba"
cp $path$pg_hba ./psql

# docker container would crash when role postgres already exist.
sed -i '/CREATE ROLE postgres/ s/^/-- /' ./psql/alldump.sql
# replace workdir in docker-compose.yml
sed -i "s|-\s.*/marvin|- ${path}/marvin|" docker-compose.yml # quiet stupid solution, how to match position in sed?

echo "apple git patch to dev code..."
cp ./patch/localize-vxm.patch ./patch/dockerize-local-vxm.patch $path$marvin
OLDPWD=$PWD
cd $path$marvin
git apply --check localize-vxm.patch &> /dev/null
if [ "$?" != 0 ]; then
	error_exit "some conflicts exist in applying localize-vxm.patch,check git status before try again."
fi
git apply localize-vxm.patch
if [ "$?" != 0 ];then
	error_exit "fail to apply the patch localize-vxm.patch."
fi

git apply --check dockerize-local-vxm.patch &> /dev/null
if [ "$?" != 0 ]; then
	error_exit "some conflicts exist in applying dockerize-local-vxm.patch,check git status before try again."
fi
git apply dockerize-local-vxm.patch	
if [ "$?" != 0 ];then
	error_exit "fail to apply the patch localize-vxm.patch."
fi
cd $OLDPWD
echo "DONE"
