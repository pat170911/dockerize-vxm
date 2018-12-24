## dockerize your local vxm
This project could help to deploy the vxm on your dev vm with docker.

The script `localize_vxm.sh` back up your entire database, copy some necessary files from remote vxm and apply git patch on your dev code to prepare for the dockerization.

Run the script below and follow the guide step by step, enter the vxm ip address, password and workspace path(or by default).
```sh
sudo sh localize_vxm.sh
```
Then use the `docker-compse` to build up the env and DONE.
```sh
docker-compose build
docker-compose up
```

Visit `http://localhost:8080` for your project.

DEBUG port: 5005, psql  port: 5432

## Some issues
If hit some errors about clock or something like that, try to sync your local time with vxm manually. 
```sh
date -s "vxm-date"
sudo timedatectl set-timezone "vxm-timezone"
```
