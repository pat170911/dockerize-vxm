# Tomcat
FROM tomcat:8.5.35
MAINTAINER pat

# create folders
RUN mkdir -m 755 /var/lib/vmware-marvin \
	&& mkdir -m 755 /var/log/mystic \
	&& mkdir -m 755 /var/lib/vmware-marvin/trust \
	&& mkdir -m 755 /etc/vmware-marvin \
	&& mkdir -m 755 /etc/vmware-marvin/ssl

# copy files
COPY context.xml /usr/local/tomcat/conf/context.xml
COPY password.key /etc/vmware-marvin
COPY runtime.properties /var/lib/vmware-marvin
COPY ./ssl/ /etc/vmware-marvin/ssl
COPY ./trust/ /var/lib/vmware-marvin/trust

ENV JPDA_ADDRESS 5005
CMD ["catalina.sh", "jpda", "run"]
