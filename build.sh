. ./docker.creds
. ./hyc.creds
CMD=${1:-docker}
$CMD images
$CMD login -u $docker_user -p $docker_token
$CMD pull docker.io/openliberty/daily:full-java11-openj9-ubi
echo 'check the OpenLiberty version, ctrl-c when complete'
$CMD run openliberty/daily:full-java11-openj9-ubi
$CMD rmi svtapps/dt7xa-n-otherapps
$CMD build -f Dockerfile.ol-dt7xa-n-otherapps -t svtapps/dt7xa-n-otherapps .
$CMD tag svtapps/dt7xa-n-otherapps docker-na-public.artifactory.swg-devops.com/hyc-wassvt-team-image-registry-docker-local/svtapps/nest-daytrader7xa-otherapps-ol-http
$CMD login docker-na-public.artifactory.swg-devops.com -u $hyc_user -p $hyc_token
$CMD push docker-na-public.artifactory.swg-devops.com/hyc-wassvt-team-image-registry-docker-local/svtapps/nest-daytrader7xa-otherapps-ol-http
