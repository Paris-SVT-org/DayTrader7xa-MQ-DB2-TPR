# Install/setup external MQ container

* Install Docker on your VM 
* Follow tutorial [Get an IBM MQ queue for development in a container](https://developer.ibm.com/tutorials/mq-connect-app-queue-manager-containers/) to install and run MQ in a docker container
```
 $ docker pull icr.io/ibm-messaging/mq
 $ docker volume create qm1data
 $ docker run --name mq --env LICENSE=accept --env MQ_QMGR_NAME=QM1 --volume qm1data:/mnt/mqm --publish 1414:1414 --publish 9443:9443 --detach --env MQ_APP_PASSWORD=passw0rd icr.io/ibm-messaging/mq
 $ docker ps
   CONTAINER ID   IMAGE              COMMAND            CREATED         STATUS         PORTS                                                                                            NAMES
   712d8e9fdab0   ibmcom/mq:latest   "runmqdevserver"   7 seconds ago   Up 5 seconds   0.0.0.0:1414->1414/tcp, :::1414->1414/tcp, 0.0.0.0:9443->9443/tcp, :::9443->9443/tcp, 9157/tcp   kind_zhukovsky
 $ docker exec -it mq bash
  bash-4.4$ dspmqver
 Name:        IBM MQ
 Version:     9.3.0.0
 Level:       p930-L220606
 BuildType:   IKAP - (Production)
 Platform:    IBM MQ for Linux (x86-64 platform)
 Mode:        64-bit
 O/S:         Linux 5.15.0-27-generic
 O/S Details: Red Hat Enterprise Linux 8.6 (Ootpa)
 InstName:    Installation1
 InstDesc:    IBM MQ V9.3.0.0 (Unzipped)
 Primary:     N/A
 InstPath:    /opt/mqm
 DataPath:    /mnt/mqm/data
 MaxCmdLevel: 930
 LicenseType: Developer
 
  bash-4.4$ dspmq
  QMNAME(QM1)                                               STATUS(Running)
```
* Access MQ console. See Step 2: Access the MQ console in https://developer.ibm.com/tutorials/mq-setting-up-using-ibm-mq-console/ (_e.g. https://<hostname where MQ docker container running>:9443/ibmmq/console login with admin/passw0rd. This is the password specified when running the MQ docker container_)
* From the IBM MQ console, create the queue `TradeBrokerQueue` and the topic `TradeStreamerTopic`. 
  Then add user app to queue authority records so that the user can perform some actions on the queue/topic
    - To create queue `TradeBrokerQueue`, in MQ console > Manage (_under Queue manager: QM1 and Queues tab_) > Create > Local > Enter T`radeBrokerQueue` for Queue name. Leave other fields with default values. Click create.
    - Add user `app` to `TradeBrokerQueue`. On Queues tab, click on TradeBrokerQueue > Actions > View configuration > Security tab > add > enter user name `app` and give it `Browse`, `Inquire`, `Get` and `Put` permissions
    - To create `TradeStreamerTopic`, in Manage QM1 > Topics tab > Create > enter TradeStreamerTopic for Topic name and Topic string
    - Add user `app` to `TradeStreamerTopic` authority records. Click TradeStreamerTopic > View configuration > Security > Add. Enter username `app` and give it `Publish` and `Subscribe` permissions

* Restart Queue Manager `QM1`. Login the MQ docker container (docker exec -it <containerid> bash) and run the following commands:
```
- Stop QM1
 bash-4.4$ endmqm -i QM1
 IBM MQ queue manager 'QM1' ending.
 IBM MQ queue manager 'QM1' ended.
 
 - Start QM1
 bash-4.4$ strmqm QM1
 Successfully applied automatic configuration INI definitions.
 IBM MQ queue manager 'QM1' starting.
 The queue manager is associated with installation 'Installation1'.
 6 log records accessed on queue manager 'QM1' during the log replay phase.
 Log replay for queue manager 'QM1' complete.
 Transaction manager state recovered for queue manager 'QM1'.
 IBM MQ queue manager 'QM1' started using V9.2.2.0.

 bash-4.4$ dspmq
 QMNAME(QM1)                                               STATUS(Running)
```
    - Note that it is normal that the App channel `DEV.APP.SVRCONN` on queue manager QM1 shows as Inactive before running any app (_no connection to the queue yet_), once you run some transactions buy/sell on daytrader, the channel will become active (_shown as 'Running'_). 
    To view this in MQ console, navigate to Manage QM1 > Communication > App channels
    - If you have problems with MQ, you can look at the MQ error log to see more details. The MQ error log can be viewed from inside the MQ container under `/var/mqm/qmgrs/QM1/errors`
  
#  Start container on host reboot
** On the on-prem host ( RedHat 9 with podman ) example as non-root user nest:

  start the svtmq container .  It must be running to generate the systemd file
  ```
  podman generate systemd --new --name mq > ~/.config/systemd/user/svtmq.service
  systemctl --user list-unit-files svtmq.service
  systemctl --user enable --now  svtmq.service
  ```
  test via host reboot
  
# Backup a MQ container
To backup/save content of a current MQ container and run it on a different machine, use [docker commit](https://docs.docker.com/engine/reference/commandline/commit/) command to save to a new image, and use [docker-volumes.sh](https://github.com/ricardobranco777/docker-volumes.sh/blob/master/docker-volumes.sh) script to save/load the container volumes

For example:
- stop the MQ container
```
# docker ps
CONTAINER ID   IMAGE              COMMAND                  CREATED        STATUS        PORTS                                                          NAMES
d9c08de17617   ibmcom/db2         "/var/db2_setup/lib/…"   27 hours ago   Up 27 hours   22/tcp, 55000/tcp, 60006-60007/tcp, 0.0.0.0:50000->50000/tcp   dtdb2
32cc827ce10f   ibmcom/mq:latest   "runmqdevserver"         3 months ago   Up 3 days     0.0.0.0:1414->1414/tcp, 0.0.0.0:9443->9443/tcp, 9157/tcp       musing_lovelace

# docker stop 32cc827ce10f
32cc827ce10f
``` 
- Create a new image
```
# docker commit 32cc827ce10f mqcontainer
sha256:f5ac58735ac556c088d445c393f0b77ce63cf0d39b3c9087a81b1030a41f01f0
```
- save the image to a .tar file
```
# docker save -o mqcontainer.tar mqcontainer
```
- save the container volumes
```
# ./docker-volumes.sh 32cc827ce10f save mqcontainer-volumes.tar
```
- copy the tar files to another machine where you want to run the MQ containter
```
# scp mqcontainer.tar mqcontainer-volumes.tar <user>@<newHost>.fyre.ibm.com:/opt/backup-restore-containers
```
- Load and run the MQ container on a new VM.  See [README](https://github.ibm.com/was-svt/DayTrader7xa-MQ-DB2-TPR#setup-db2-and-mq-containers) 
