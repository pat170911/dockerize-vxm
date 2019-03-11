FROM postgres:9.6.10
MAINTAINER pat
#ENV POSTGRES_USER admin  
#ENV POSTGRES_PASSWORD password  

EXPOSE 5432

COPY pg_hba.conf /etc/postgresql/9.6/main/
COPY alldump.sql /docker-entrypoint-initdb.d/
