#!/bin/bash

# the vxm ip address
ip=
# the vxm root password
password=
# the marvin project dir
path=/home/mystic/workspace && marvin=/marvin
# dependent package
dep_pkg=("sshpass")

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

command_status()
{
	if [ "$1" != 0 ];then
		error_exit "$2"
	fi
}

usage()
{
	echo "Usage: $0 [-h host -p password | -i | -h]"
	echo "       -a --address       IP address of the vxm host"
	echo "       -p --password      Root password of the vmx host"
	echo "       -i --interactive   Enter the interactive mode"
	echo "       -h --help          Show help infomation"
	exit 1
}

check_permission()
{
	if [ $(id -u) != "0" ]; then
		error_exit "no root privileges: Permission denied" 
	fi
}


check_ip()
{
	if [ ! -n "$1" ]; then
		error_exit "no IP entry."
	fi
	ping -c 3 "$1" &> /dev/null
	command_status "$?" "host $ip not found."
}

configure_files()
{
	cp -r ./trust ./ssl password.key runtime.properties ./tomcat && rm -rf ./trust ./ssl password.key runtime.properties
	if [ -a ./psql/alldump.sql ]; then
		cp -r ./psql/alldump.sql ./psql/alldump.sql.bak
	fi
	cp -r ./alldump.sql ./psql && rm -R ./alldump.sql
	chmod -R 755 ./tomcat/trust ./tomcat/ssl 
	chmod 644 ./tomcat/password.key ./tomcat/runtime.properties ./psql/alldump.sql
	
	# docker container would crash when role postgres already exist.
	sed -i '/CREATE ROLE postgres/ s/^/-- /' ./psql/alldump.sql
	command_status "$?" "fail to amend ./psql/alldump.sql, check it manually."
}

check_dev_path()
{
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

	# replace workdir in docker-compose.yml
	sed -i "s|-\s.*/marvin|- ${path}/marvin|" docker-compose.yml # quiet stupid solution, how to match position in sed?
	command_status "$?" "fail to replace the dev path in docker-compose.yml, check it manually."
}

apply_patch()
{
	echo "apple git patch to dev code..."
	cp ./patch/localize-vxm.patch ./patch/dockerize-local-vxm.patch $path$marvin
	OLDPWD=$PWD
	cd $path$marvin
	git apply --check localize-vxm.patch &> /dev/null
	command_status "$?" "some conflicts exist in applying localize-vxm.patch,check git status before try again."
	git apply localize-vxm.patch
	command_status "$?" "fail to apply the patch localize-vxm.patch."
	
	git apply --check dockerize-local-vxm.patch &> /dev/null
	command_status "$?" "some conflicts exist in applying dockerize-local-vxm.patch,check git status before try again."
	git apply dockerize-local-vxm.patch	
	command_status "$?" "fail to apply the patch localize-vxm.patch."
	cd $OLDPWD
}

install_dependency()
{
	for pkg in $dep_pkg; do
		dpkg -s "$package" &> /dev/null
		if [ "$?" != 0 ]; then
			echo "install dependent package $pkg..."
			apt-get update &> /dev/null
			apt-get -y install $pkg &> /dev/null
		fi
	done
}

sshpass_mode()
{
	check_permission

	check_ip "$ip"
	
	install_dependency

	echo "backup remote database..."
	sshpass -p $password ssh root@$ip "pg_dumpall -U postgres > ~/alldump.sql" # may have synchronization problem.

	echo "copy certificate files..."
	sshpass -p $password scp -r root@$ip:'/var/lib/vmware-marvin/trust \
						                  /etc/vmware-marvin/ssl \
					 					  /etc/vmware-marvin/password.key \
					 					  /var/lib/vmware-marvin/runtime.properties \
					 					  ~/alldump.sql' .
	
	configure_files

	check_dev_path
	
	apply_patch

	echo "sync date with remote vxm..."
	date --set="$(sshpass -p $password ssh root@$ip 'date -u')" &> /dev/null
	command_status "$?" "fail to sync the date, check it manually."
}

interact_mode()
{
	check_permission

	echo -n "enter the IP of vxm > "
	read text
	ip=$text
	check_ip "$ip"

	echo "backup remote database, enter vxm password..."
	ssh root@$ip "pg_dumpall -U postgres > ~/alldump.sql" # may have synchronization problem.

	echo "copy certificate files, enter vxm password..."
	scp -r root@$ip:'/var/lib/vmware-marvin/trust \
					 /etc/vmware-marvin/ssl \
					 /etc/vmware-marvin/password.key \
					 /var/lib/vmware-marvin/runtime.properties \
					 ~/alldump.sql' .
	
	configure_files

	check_dev_path

	apply_patch

	
	echo "sync date with remote vxm, enter vmx password..."
	date --set="$(ssh root@$ip 'date -u')" 
	command_status "$?" "fail to sync the date, check it manually."

}

#if [ -z "$1" ]; then
#	usage
#fi

while true; do
	case "$1" in
		-a | --address)		shift
							ip="$1"
							if [ -n "$password" ]; then
								sshpass_mode
								break
							fi
							;;
		-p | --password)	shift
							password="$1"
							if [ -n "$ip" ]; then
								sshpass_mode
								break
							fi
							;;
		-i | --interactive) interact_mode
							break
							;;
		-h | --help)		usage
							;;
		*)					usage
							;;
	esac
	shift
done

#echo "copy pg_nba.conf from dev code..."
#pg_hba="/marvin/application/mystic.manager/mystic.manager.commons/mystic.manager.commons.db/src/main/resources/conf/pg_hba.conf"
#file_exist "$path$pg_hba"
#cp $path$pg_hba ./psql

# replace workdir in docker-compose.yml
sed -i "s|-\s.*/marvin|- ${path}/marvin|" docker-compose.yml # quiet stupid solution, how to match position in sed?

echo "DONE"
exit 0
