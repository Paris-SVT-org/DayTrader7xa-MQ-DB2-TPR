# DayTrader7xa-MQ-DB2-TPR


* apps/daytrader-ee7-xa.ear application is used to test Transaction Peer Recovery with Asychronous 2-Phase commit transactions
* The application source code is located under sample.daytrader7-xa directory. The app context root is /daytrader-xa
* The app also uses external MQ container

* DayTrader provides an asynchronous order processing mode through messaging with MDBs. The order processing mode determines the mode for completing stock purchase and sell operations. Synchronous mode completes the order immediately. *Asynchronous* mode uses MDB and JMS to queue the order to a TradeBroker agent to complete the order. Asychronous 2-Phase performs a two-phase commit over the EJB database and messaging transactions.
  - Synchronous - Orders are completed immediately by the DayTrader session enterprise bean and entity enterprise beans.
  - Asynchronous 2-phase - Orders are queued to the TradeBrokerMDB for asynchronous processing.

## application image location

The application docker image was built and push to artifactory https://na.artifactory.swg-devops.com/ui/repos/tree/General/hyc-wassvt-team-image-registry-docker-local%2Fsvtapps
- Daytrader7 on Open Liberty latest image: 
* `applicationImage: 'docker-na-public.artifactory.swg-devops.com/hyc-wassvt-team-image-registry-docker-local/daytrader/nest-daytrader7xa-otherapps-ol-http'
  
## Build application image

If you want to make any modification and rebuild that application image, follow the following steps:

```
$ docker build -f Dockerfile.ol-dtxa-n-otherapps -t <dockerid>/dt7xa-n-otherapps-ol .
$ docker push <dockerid>/dt7xa-n-otherapps-ol   # to push the image to docker hub
#to push app image to artifactory, tag the image and push it, for example:
$ docker tag <dockerid>/dt7xa-n-otherapps-ol docker-na-public.artifactory.swg-devops.com/hyc-wassvt-team-image-registry-docker-local/svtapps/dt7xa-n-otherapps-ol
$ docker login https://docker-na-public.artifactory.swg-devops.com
$ docker push docker-na-public.artifactory.swg-devops.com/hyc-wassvt-team-image-registry-docker-local/svtapps/dt7xa-n-otherapps-ol
```
## Setup DB2 and MQ containers

- Setup DB2 container
  - On a VM that you want to run DB2 container, install docker if not exist
  - run DB2 docker container
  ```
  # docker run --name dtdb2 --restart=always --detach --privileged=true -p 50000:50000 -e LICENSE=accept -e DB2INST1_PASSWORD=passw0rd -e DBNAME=tradedb ibmcom/db2
  ```
    - Notes:  if ibmcom/db2 image does not exist, it will pull it automatically.
	  Default DB2 instance name is db2inst1. Mapping port parameter -p xxx:yyy where xxx is port on VM where the 	container is running and yyy is the DB2 container connection port
  
  - View dtdb2 container to make sure it's running ok
  ```
  # docker ps -a
  CONTAINER ID  IMAGE                         COMMAND     CREATED         STATUS             PORTS                                           NAMES
  a5f970268250  docker.io/ibmcom/db2:latest               45 minutes ago  Up 45 minutes ago  0.0.0.0:50000->50000/tcp                        dtdb2
  ```

  - To check for TRADEDB in the container
  ```
  # docker exec -it dtdb2 bash
  # su - db2inst1
  $ db2 list db directory
  ```

- Run MQ container (_can be run on the same VM as the DB2 container_)
	- [MQ setup](MQ/README-mq.md)
  

## Deploy application to OCP cluster

- Install Open Liberty Operator
- Create namespace to deploy Daytrader application:  oc new-project svt-daytrader
- If you cluster is not configured with any storage, you can deploy Ceph storage by running script [ceph.sh](https://github.ibm.com/websphere/automation-build/blob/main/security/deploy/scripts/ceph.sh) or [Minimal Ceph Storage setup on Fyre OCP+ Beta cluster for testing](https://github.ibm.com/IBMCloudPak4Apps/icpa-system-test/wiki/Configuring-Storage-on-OCP#minimal-ceph-storage-setup-on-fyre-ocp-beta-cluster-for-testing)
- Create Persistent Volume Claim (PVC). Login OpenShift console > Storage > PersistentVolumeClaims and create `dt-pvclaim` with the following info
```
 apiVersion: v1
 kind: PersistentVolumeClaim
 metadata:
   name: dt-pvclaim
   namespace: svt-daytrader
 spec:
   accessModes:
     - ReadWriteMany
   storageClassName: rook-cephfs
   resources:
     requests:
       storage: 2Gi
   volumeMode: Filesystem
```

- Create `db-credential` secret on the same namespace that you plan to deploy the app.  For example,
```
 $ echo passw0rd > dbpw
 $ oc -n svt-daytrader create secret generic db-credential --from-file=./dbpw
```

- Create pull secret to allow pods to reference images from other secured registries (https://docs.openshift.com/container-platform/4.7/openshift_images/managing_images/using-image-pull-secrets.html#images-allow-pods-to-reference-images-from-secure-registries_using-image-pull-secrets)

- For example:
```
$ oc -n svt-daytrader create secret docker-registry pull-secret-dt7xa \
> --docker-server=hyc-wassvt-team-image-registry-docker-local.artifactory.swg-devops.com \
> --docker-username=tamdinh@us.ibm.com \
> --docker-password=<my artifactory keyid> \
> --docker-email=mymail@us.ibm.com
```

- Add the secret to your service account. The name of the service account should match the name of the service account the pod uses (oc describe pod <podName> to see the service account the pod is using.  e.g. `/var/run/secrets/kubernetes.io/serviceaccount from nest-ocp-dt7xa-extmq-token-6dd4l (ro)`.  To view all service accounts under the current namespace, run oc get sa)
    - `oc secrets link <pod service account> <pull secret name> --for=pull`
    -  e.g. oc secrets link nest-ocp-dt7xa-extmq pull-secret-dt7xa --for=pull
- specify the pull secret in the examples/deploy-dt7xa.yml `spec.pullSecret: "pull-secret-dt7xa"`


 - Edit examples/deploy-dt7xa.yml file to point to the DB2 and MQ containers under `spec.env` section
 - If you want to deploy the app as deployment, uncomment spec.deployment section and comment out spec.statefulSet section 
  * Notes: as of August 9, 2021. The examples/deploy-dt7xa.yml is using DB2 server `9.46.75.196` and external MQ which is running in a docker container on VM `9.46.86.72`.  It is not garantee that the DB2 server and external MQ are still running when you use this application.  So it's best to setup your own DB2 and MQ containers follow the above instruction
 
 - Deploy  application to OCP:  
  `oc apply -f examples/deploy-dt7xa.yml`
  - view pods _oc get pods_ to make sure app pod is running ok
  
## Deploy application to the performance peroni OCP cluster

- Create `dt-pvclaim` with `storage: 10Gi` for stress test
- Create `db-credential` secret using password for DB2 server `nest-dt7xa-ocp-svl-db.fyre.ibm.com` 
- Create pull secret and add it to the pod service account
- deploy app: `oc apply -f examples/deploy-dt7xa-nest-http.yml`
  - Notes: the examples/deploy-dt7xa-nest-http.yml has the DB2 and external MQ information in the `spec.env` variables

## Run Daytrader application

Run Daytrader7xa application from the route url with context root `daytrader-xa`. 

For example: `http://dtee7-xa-svt-daytrader.apps.tam-ocp48.cp.fyre.ibm.com/daytrader-xa/`


- Populate data to TRADEDB (_from DayTrader app console after succesfully deploy to OCP_).
  - launch DayTrader app `https://<rooute-url>/daytrader-xa/`
  - For quick test, you can adjust max users and quotes to smaller values to populate data faster.  For example, click Configuration tab > Configure DayTrader run-time parameters > set DayTrader Max Users=150, Trade Max Quotes=100 > Update Config
  - Click (Re)-populate  DayTrader Database link in the Configuration tab to populate data

- Populate data in TRADEDB
  - launch DayTrader app https://<route-url>/daytrader-xa/
  - For quick test, you can adjust max users and quotes to smaller values to populate data faster.  For example, click Configuration tab > Configure DayTrader run-time parameters > set DayTrader Max Users=150, Trade Max Quotes=100.  Click `Update Config`
  - Click (Re)-populate  DayTrader Database link in the Configuration tab to populate data
  - To check for TRADEDB in the container
  ```
  # docker exec -it dtdb2 bash
  # su - db2inst1
  $ db2 list db directory
  $ db2 connect to TRADEDB
  $ db2 list tables

  Table/View                      Schema          Type  Creation time             
  ------------------------------- --------------- ----- --------------------------
  ACCOUNTEJB                      DB2INST1        T     2021-11-20-00.28.55.680230
  ACCOUNTPROFILEEJB               DB2INST1        T     2021-11-20-00.28.54.886853
  HOLDINGEJB                      DB2INST1        T     2021-11-20-00.28.54.596836
  KEYGENEJB                       DB2INST1        T     2021-11-20-00.28.55.413446
  ORDEREJB                        DB2INST1        T     2021-11-20-00.28.55.970022
  QUOTEEJB                        DB2INST1        T     2021-11-20-00.28.55.150843

    6 record(s) selected.
  
  $ db2 select count from accountejb

  1          
  -----------
        150

  1 record(s) selected.

  $ db2 select count from accountejb

  1          
  -----------
        150

  1 record(s) selected.

  $ db2 select count from quoteejb

  1          
  -----------
        100

  1 record(s) selected.
  ```
  - Login Daytrader app in `Trading & Portfolios` tab, buy stocks under `Quotes/Trade` and sell stocks in the `Portfolio` tab
  
## Day-2 Operations

See https://github.com/OpenLiberty/open-liberty-operator/blob/master/doc/user-guide-v1beta2.adoc#day-2-operations

- Create Storage for serviceability (_see spec.serviceability in examples/deploy-dt7xa.yml_)
- Request server thread and heap dump on a running pod, apply the following: 

```
apiVersion: apps.openliberty.io/v1beta2
kind: OpenLibertyDump
metadata:
  name: get-oldump
  namespace: svt-daytrader
spec:
  podName: ol-dt7xa-0 #specify pod name
  include:
    - thread
    - heap
```
- Request server traces on a running pod, apply the following

```
apiVersion: apps.openliberty.io/v1beta2
kind: OpenLibertyTrace
metadata:
  name: get-trace
  namespace: svt-daytrader
spec:
  podName: ol-dt7xa-0 #specify pod name
  traceSpecification: "*=info:com.ibm.ws.webcontainer*=all" #specify trace string
  maxFileSize: 20
  maxFiles: 5
```
- messages.log, trace.log, and dump files will be in folder /serviceability/NAMESPACE/POD_NAME/
