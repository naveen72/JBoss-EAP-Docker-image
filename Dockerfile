#######################################################################
# Creates a base Centos 6.6 image with JBoss EAP-6.3.0.GA r2              #
#######################################################################

# Use the centos 6.6 base image
FROM centos:6.6 

MAINTAINER fbascheper <temp01@fam-scheper.nl>

# Update the system
RUN yum -y update;yum clean all

##########################################################
# Install Java JDK
##########################################################
RUN yum -y install wget && \
    wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/7u72-b14/jdk-7u72-linux-x64.rpm && \
    echo "c55acf3c04e149c0b91f57758f6b63ce  jdk-7u72-linux-x64.rpm" >> MD5SUM && \
    md5sum -c MD5SUM && \
    rpm -Uvh jdk-7u72-linux-x64.rpm && \
    yum -y remove wget && \
    rm -f jdk-7u72-linux-x64.rpm MD5SUM

ENV JAVA_HOME /usr/java/jdk1.7.0_72

# Perform the "Yes, I want grownup encryption" Java ceremony
RUN mkdir -p /tmp/UnlimitedJCEPolicy
ADD ./jce-unlimited/US_export_policy.jar /tmp/UnlimitedJCEPolicy/US_export_policy.jar
ADD ./jce-unlimited/local_policy.jar     /tmp/UnlimitedJCEPolicy/local_policy.jar
RUN mv /tmp/UnlimitedJCEPolicy/*.*       $JAVA_HOME/jre/lib/security/
RUN rm -rf /tmp/UnlimitedJCEPolicy*

# Add CA certs
ADD ./trusted-root-ca/StaatderNederlandenRootCA-G2.pem     /tmp/StaatderNederlandenRootCA-G2.pem
RUN $JAVA_HOME/bin/keytool -import -noprompt -trustcacerts -alias StaatderNederlandenRootCA-G2 -file  /tmp/StaatderNederlandenRootCA-G2.pem -keystore $JAVA_HOME/jre/lib/security/cacerts -storepass changeit


##########################################################
# Create jboss user
##########################################################

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN groupadd -r jboss && useradd -r -g jboss -m -d /home/jboss jboss


############################################
# Install EAP 6.3.2.GA
############################################
RUN yum -y install zip unzip

USER jboss
ENV INSTALLDIR /home/jboss/EAP-6.3.0
ENV HOME /home/jboss

RUN mkdir $INSTALLDIR && \
   mkdir $INSTALLDIR/distribution && \
   mkdir $INSTALLDIR/resources


USER root
ADD distribution $INSTALLDIR/distribution
RUN chown -R jboss:jboss /home/jboss
RUN find /home/jboss -type d -execdir chmod 770 {} \;
RUN find /home/jboss -type f -execdir chmod 660 {} \;

USER jboss
RUN unzip $INSTALLDIR/distribution/jboss-eap-6.3.0.zip  -d $INSTALLDIR
RUN $INSTALLDIR/jboss-eap-6.3/bin/jboss-cli.sh "patch apply $INSTALLDIR/distribution/jboss-eap-6.3.2-patch.zip"


############################################
# Create start script to run EAP instance
############################################
USER root

RUN yum -y install curl
RUN curl -o /usr/local/bin/gosu -SL 'https://github.com/tianon/gosu/releases/download/1.1/gosu' \
	&& chmod +x /usr/local/bin/gosu

############################################
# Remove install artifacts
############################################
RUN rm -rf $INSTALLDIR/distribution
RUN rm -rf $INSTALLDIR/resources

############################################
# Add customization sub-directories (for entrypoint)
############################################
ADD docker-entrypoint-initdb.d  /docker-entrypoint-initdb.d
RUN chown -R jboss:jboss        /docker-entrypoint-initdb.d
RUN find /docker-entrypoint-initdb.d -type d -execdir chmod 770 {} \;
RUN find /docker-entrypoint-initdb.d -type f -execdir chmod 660 {} \;

ADD modules  $INSTALLDIR/modules
RUN chown -R jboss:jboss $INSTALLDIR/modules
RUN find $INSTALLDIR/modules -type d -execdir chmod 770 {} \;
RUN find $INSTALLDIR/modules -type f -execdir chmod 660 {} \;

############################################
# Expose paths and start JBoss
############################################

EXPOSE 22 5455 9999 8009 8080 8443 3528 3529 7500 45700 7600 57600 5445 23364 5432 8090 4447 4712 4713 9990 5005

RUN mkdir /etc/jboss-as
RUN mkdir /var/log/jboss/
RUN chown jboss:jboss /var/log/jboss/

COPY docker-entrypoint.sh /
RUN chmod 700 /docker-entrypoint.sh

############################################
# Start JBoss in stand-alone mode
############################################

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["start-jboss"]
