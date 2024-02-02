FROM websphere-liberty:latest

#Handle exit code 22 - the feature already exists.
RUN installUtility install --acceptLicense logstashCollector-1.0; if [ $? -eq 0 -o $? -eq 22 ]; then exit 0; else exit $?; fi

COPY daytrader-ee7-wlpcfg/servers/daytrader7Sample/apps/daytrader-ee7.ear /config/apps/daytrader-ee7.ear
COPY server.xml /config/server.xml
COPY jvm.options /config/jvm.options

#DERBY
#COPY daytrader-ee7-wlpcfg/servers/daytrader7Sample/server.xml /config/server.xml
#COPY daytrader-ee7-wlpcfg/shared/resources/Daytrader7SampleDerbyLibs/derby-10.10.1.1.jar /opt/ibm/wlp/usr/shared/resources/Daytrader7SampleDerbyLibs/derby-10.10.1.1.jar

#DB2
COPY db2jars/db2jcc4.jar /opt/ibm/wlp/usr/shared/resources/db2jars/db2jcc4.jar
