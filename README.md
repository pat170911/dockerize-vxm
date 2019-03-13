## dockerize your local vxm
This util could help to deploy the vxm on your dev vm with docker.

The script `localize_vxm.sh` back up your entire database, copy some necessary files from remote vxm and apply git patch on your dev code to prepare for the dockerization.

Run the script with -i (--interactive), it will prompt you to enter the vxm ip address, password and workspace path(or by default). Or use ip and password as parameters.
```sh
sudo ./localize-vxm -i
# or
sudo sh localize_vxm.sh -a vxm_ip_address -p vxm_root_password
```

The localize_vxm.sh has implied some patch on your dev code, so make sure to `make` your project or just build the artifact in mystic.manager.web:war explode
Then use the `docker-compse` to build up the env and DONE.
```sh
docker-compose build
# before up, sometime you need to rebuild your code in IDE to refresh.
docker-compose up
```

Visit `http://localhost:8080` for your project.
DEBUG port: 5005, psql  port: 5432
Log file and database can be accessed by this,
```sh
sudo docker exec -it tomcat tail -f /var/log/mystic/web.log
sudo docker exec -it psql psql -h localhost -p 5432 -U postgres
```

## some issues
If hit some errors about clock or vc certificate, try to sync your local time with vxm manually. 
```sh
sudo date --set="$(ssh root@192.168.x.x 'date -u')
#sometimes also need
sudo timedatectl set-timezone "vxm-timezone(UTC)"
```
