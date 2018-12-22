##dockerize your local vxm
This environment could save your time from building your code to installing on the remote vxm.
The script localize_vxm.sh back up your entire database copy some ssl file and apply git patch on your dev to prepare for the dockerization.
Just run `source localize_vxm.sh` and follow the guide step by step, enter the vxm ip address, password and workspace path(or use the default).
when finished, use the `docker-compse` to build up the env.
```sh
docker-compose build
docker-compose up
```
DONE!
Visit `http://localhost:8080` for your project.

The tomcat container portforward `8080` to the outside.
The psql container portforward `5432` to the outside.

