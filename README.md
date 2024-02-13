# Deploying Daytrader7 Sample chart with Microservice Builder (test)

Daytrader7 requires two databases. daytrader-trade and daytrader-session. These databases should be deployed from the official db2-c helm chart, as per below. The Daytrader7 chart expects these specific names for service wiring, as seen in the deployment.yaml.

This example uses the glusterfs distributed storage which can be configured by the substrate-kubernetes scripts. 

```
helm install --name daytrader-trade --set persistence.useDynamicProvisioning=true --set dataVolume.storageClassName=glusterfs --set dataVolume.size=5Gi --set image.secret=eyJuYS5jdW11bHVzcmVwby5jb20iOnsidXNlcm5hbWUiOiJ0b2tlbiIsInBhc3N3b3JkIjoiOTkxOTE5NGIwMDU3MDM0N2FmZTA1YmQzNjljN2Y3MmYiLCJlbWFpbCI6ImlkZWxpZGphQGNhLmlibS5jb20iLCJhdXRoIjoiZEc5clpXNDZPVGt4T1RFNU5HSXdNRFUzTURNME4yRm1aVEExWW1Rek5qbGpOMlkzTW1ZPSJ9fQ== ibm-charts/ibm-db2oltp-dev 


helm install --name daytrader-session --set persistence.useDynamicProvisioning=true --set dataVolume.storageClassName=glusterfs --set dataVolume.size=5Gi --set image.secret=eyJuYS5jdW11bHVzcmVwby5jb20iOnsidXNlcm5hbWUiOiJ0b2tlbiIsInBhc3N3b3JkIjoiOTkxOTE5NGIwMDU3MDM0N2FmZTA1YmQzNjljN2Y3MmYiLCJlbWFpbCI6ImlkZWxpZGphQGNhLmlibS5jb20iLCJhdXRoIjoiZEc5clpXNDZPVGt4T1RFNU5HSXdNRFUzTURNME4yRm1aVEExWW1Rek5qbGpOMlkzTW1ZPSJ9fQ== ibm-charts/ibm-db2oltp-dev 
```

After deploying the db2 helm charts, you may deploy Microservice Builder targetted at the sample.daytrader7 repository as normal.

After the daytrader pod has started and is available, create the database as normal, then as required, delete the pod to restart the application.

The following testcase may be run as follows

```
jmeter -n -t dtcommon_daytrader7WebSocket_https.jmx -JHOST=icpproxy.rtp.raleigh.ibm.com -JPORT=443 -JPROTOCOL=https -JTHREADS=20 -JWEBSOCKETTHREADS=10 -JDURATION=300
```

# sample.daytrader7 [![Build Status](https://travis-ci.org/WASdev/sample.daytrader7.svg?branch=master)](https://travis-ci.org/WASdev/sample.daytrader7)

# Java EE7: DayTrader7 Sample

Java EE7 DayTrader7 Sample


This sample contains the DayTrader 7 benchmark, which is an application built around the paradigm of an online stock trading system. The application allows users to login, view their portfolio, lookup stock quotes, and buy or sell stock shares. With the aid of a Web-based load driver such as Apache JMeter, the real-world workload provided by DayTrader can be used to measure and compare the performance of Java Platform, Enterprise Edition (Java EE) application servers offered by a variety of vendors. In addition to the full workload, the application also contains a set of primitives used for functional and performance testing of various Java EE components and common design patterns.

DayTrader is an end-to-end benchmark and performance sample application. It provides a real world Java EE workload. DayTrader's new design spans Java EE 7, including the new WebSockets specification. Other Java EE features include JSPs, Servlets, EJBs, JPA, JDBC, JSF, CDI, Bean Validation, JSON, JMS, MDBs, and transactions (synchronous and asynchronous/2-phase commit).

This sample can be installed onto WAS Liberty runtime versions 8.5.5.6 and later.

## Getting Started

Browse the code to see what it does, or build and run it yourself:
* [Building and running on the command line](/docs/Using-cmd-line.md)
* [Building and running using Eclipse and WebSphere Development Tools (WDT)](/docs/Using-WDT.md)
* [Downloading WAS Liberty](/docs/Downloading-WAS-Liberty.md)

Once the server has been started, go to [http://localhost:9082/daytrader](http://localhost:9082/daytrader) to interact with the sample.

## Notice

© Copyright IBM Corporation 2015.

## License

```text
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
````
