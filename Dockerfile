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
ADD ./jce-unlimited/cacerts              /tmp/UnlimitedJCEPolicy/cacerts
ADD ./jce-unlimited/local_policy.jar     /tmp/UnlimitedJCEPolicy/local_policy.jar
RUN mv /tmp/UnlimitedJCEPolicy/*.* /usr/java/jdk1.7.0_72/jre/lib/security/
RUN rm -rf /tmp/UnlimitedJCEPolicy*

##########################################################
# Create jboss user
##########################################################

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN groupadd -r jboss && useradd -r -g jboss -m -d /home/jboss jboss


############################################
# Install EAP 6.3.0.GA and r2
############################################
RUN yum -y install zip unzip

USER jboss
ENV INSTALLDIR /home/jboss/EAP-6.3.0
ENV HOME /home/jboss

RUN mkdir $INSTALLDIR && \
   mkdir $INSTALLDIR/installer && \
   mkdir $INSTALLDIR/patches && \
   mkdir $INSTALLDIR/resources


USER root
ADD installer/jboss-eap-6.3.0-installer.jar $INSTALLDIR/installer/jboss-eap-6.3.0-installer.jar
ADD patches/jboss-eap-6.3.2-patch.zip $INSTALLDIR/patches/jboss-eap-6.3.2-patch.zip
RUN chown -R jboss /home/jboss
RUN find /home/jboss -type d -execdir chmod 770 {} \;
RUN find /home/jboss -type f -execdir chmod 660 {} \;


USER jboss
### RUN unzip $INSTALLDIR/installer/jboss-eap-6.3.0.zip  -d $INSTALLDIR
ADD resources/auto.xml $INSTALLDIR/resources/auto.xml
ADD resources/auto.xml.variables $INSTALLDIR/resources/auto.xml.variables
RUN java -jar $INSTALLDIR/installer/jboss-eap-6.3.0-installer.jar $INSTALLDIR/resources/auto.xml -variablefile $INSTALLDIR/resources/auto.xml.variables
RUN $INSTALLDIR/jboss-eap-6.3/bin/jboss-cli.sh "patch apply $INSTALLDIR/patches/jboss-eap-6.3.2-patch.zip"


############################################
# Create start script to run EAP instance
############################################
USER root
RUN echo "#!/bin/sh" >> $HOME/start.sh
RUN echo "echo JBoss EAP Start script" >> $HOME/start.sh
RUN echo "runuser -l jboss -c '$HOME/EAP-6.3.0/jboss-eap-6.3/bin/standalone.sh -c standalone-full.xml -b 0.0.0.0 -bmanagement 0.0.0.0'" >> $HOME/start.sh
RUN chmod +x $HOME/start.sh


############################################
# Remove install artifacts
############################################
RUN rm -rf $INSTALLDIR/installer
RUN rm -rf $INSTALLDIR/patches
RUN rm -rf $INSTALLDIR/resources

############################################
# Expose paths and start JBoss
############################################

EXPOSE 22 5455 9999 8080 5432 4447 5445 9990 3528

CMD /home/jboss/start.sh

# Finished
