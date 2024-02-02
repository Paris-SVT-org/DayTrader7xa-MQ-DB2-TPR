ARG BASE_IMAGE=icr.io/appcafe/open-liberty:kernel-slim-java8-openj9-ubi
FROM $BASE_IMAGE

#Daytrader-ee7-xa (2-phase commit) app
COPY --chown=1001:0 apps/daytrader-ee7-xa.ear /config/apps/daytrader-ee7-xa.ear
COPY --chown=1001:0 server-dt7xa.xml /config/server.xml
COPY --chown=1001:0 jvm.options /config/
#user defined xaflow-1.0 feature to test transaction manager 
#remove for NEST to avoid too many messages in the log
#COPY --chown=1001:0 xaflow.jar  /opt/ol/wlp/lib
#COPY --chown=1001:0 xaflow-1.0.mf /opt/ol/wlp/lib/features

# IBM MQ Resource Adapter
COPY --chown=1001:0 wmq.jmsra.rar /config

#DB2
COPY --chown=1001:0 db2jars /config/db2jars

#demo app to manually verify transaction peer revovery test
#using environment variable killOn=commit or sleepOn=commit
#e.g. (http://<hostname>/peer-recovery-demo/demo?killOn=commit)
COPY --chown=1001:0  apps/peer-recovery-demo.war /config/dropins/
COPY --chown=1001:0  bootstrap.properties /config/

# Getting sharedApps and copy to /config/dropins/
# see utility apps release notes to determine what app version to use
# https://github.ibm.com/was-svt/svtMessageApp/releases 
# https://github.ibm.com/was-svt/microwebapp/releases 
# https://github.ibm.com/was-lumberjack/badapp/releases

User root

RUN --mount=type=secret,id=token --mount=type=secret,id=user\
       mkdir -p /mytemp && cd /mytemp \
       && curl --retry 7 -sSf -u $(cat /run/secrets/user):$(cat /run/secrets/token) \
      -O 'https://na.artifactory.swg-devops.com/artifactory/hyc-wassvt-team-maven-virtual/svtMessageApp/svtMessageApp/1.0.3/svtMessageApp-1.0.3.war' \
      && curl --retry 7 -sSf -u $(cat /run/secrets/user):$(cat /run/secrets/token) \
      -O 'https://na.artifactory.swg-devops.com/artifactory/hyc-wassvt-team-maven-virtual/microwebapp/microwebapp/1.0.1/microwebapp-1.0.1.war' \
      && curl --retry 7 -sSf -u $(cat /run/secrets/user):$(cat /run/secrets/token) \
      -O 'https://na.artifactory.swg-devops.com/artifactory/hyc-wassvt-team-maven-virtual/com/ibm/ws/lumberjack/badapp/1.0.1/badapp-1.0.1.war' \
      && chown -R 1001:0 /mytemp/*.war  && mv /mytemp/*.war /config/dropins
      
user 1001

VOLUME /shared-tranlogs

# Optional functionality
#ARG SSL=true
ARG MP_MONITORING=true
ARG MP_HEALTH_CHECK=true
ARG VERBOSE=true         #verbose option
ARG FULL_IMAGE=false
# Enable Transport Security in Liberty by adding the transportSecurity-1.0 feature
ARG TLS=true

# This script will add the requested XML snippets to enable Liberty features and grow image to be fit-for-purpose using featureUtility. 
# Only available in 'kernel-slim'. The 'full' tag already includes all features for convenience.

RUN if [ "$FULL_IMAGE" = "true" ] ; then echo "Skip running features.sh for full image" ; else features.sh ; fi

# This script will add the requested XML snippets and grow image to be fit-for-purpose
RUN configure.sh
