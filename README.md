
## JBoss EAP 6.4.3 Docker image
This project builds a docker container for running JBoss EAP 6.4.3.GA.


Before running the build:

1. Install [Docker](https://www.docker.io/gettingstarted/#1)
2. Setup the /distribution directory, by adding the JBoss EAP 6.4.0 zip distribution and any roll-up patch files (jboss-eap-6.4.0.zip / jboss-eap-6.4.x-patch.zip)
3. Setup the /jce-unlimited directory, by adding the JCE unlimited policy files (local_policy.jar / US_export_policy.jar)
4. Setup the /trusted-root-ca directory, by adding your trusted root CA files (in .pem format)

Once you have completed steps 1..4 you can build an image using the following command:

		$ docker build -t fbascheper/redhat-jboss-eap .
		$ docker build -t fbascheper/redhat-jboss-eap:6.4.3 .
        $ docker push fbascheper/redhat-jboss-eap
        $ docker push fbascheper/redhat-jboss-eap:6.4.3               §


You can run the JBoss-EAP container and automatically start an EAP instance with the following command::

        $ docker run -P -it --rm -e JBOSS_USER=jbossadmin -e JBOSS_PASSWORD=jboss@min1 \
        	fbascheper/redhat-jboss-eap:6.4.3 


Or you can run the container linked to postgres-td container and start a bash shell or jboss-cli.sh (as user jboss)

        $ docker run -P -it --rm -e JBOSS_USER=jbossadmin -e JBOSS_PASSWORD=jboss@min1 \
        	fbascheper/redhat-jboss-eap:6.4.3 bash
        	
        $ docker run -P -it --rm -e JBOSS_USER=jbossadmin -e JBOSS_PASSWORD=jboss@min1 \
        	fbascheper/redhat-jboss-eap:6.4.3 jboss-cli.sh -c



The extension-mechanism works in the same fashion as the postgresql docker image, i.e. by adding your own shell script in the docker-entrypoint directory.
