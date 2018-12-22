## dockerize your local vxm
This environment could help to deploy the vxm on your dev vm with docker saving time from building project to installed on the remote vxm.

The script `localize_vxm.sh` back up your entire database copy some ssl file and apply git patch on your dev to prepare for the dockerization.
Run the script below and follow the guide step by step, enter the vxm ip address, password and workspace path(or by default).
```sh
sudo source localize_vxm.sh
```
Then use the `docker-compse` to build up the env and DONE.
```sh
docker-compose build
docker-compose up
```

Visit `http://localhost:8080` for your project.
DEBUG port: 5005
psql  port: 5432
