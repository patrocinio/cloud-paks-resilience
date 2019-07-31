PROJECT=cp4i
SCC=ibm-privileged-scc
INSTALL_DIR=/root/Integration/install/installer_files/cluster/icipcontent
APIC=IBM-API-Connect-Enterprise-for-IBM-Cloud-Integration-Platform-1.0.0.tgz
APIC_CHART=ibm-apiconnect-cip-prod-1.0.0.tgz
WORK_DIR=/root/work_cp4i
IMAGE_DIR=/images/Integration/2019.3.1
IMAGE=ibm-cloud-pak-for-integration-x86_64-2019.3.1-for-OpenShift.tar.gz

function unzipImage {
  echo Unzipping image...
  tar xzvf $IMAGE_DIR/$IMAGE
}

function createProject {
  echo Creating project...
  oc new-project $PROJECT
}

function updateSCC {
  echo Updating Security Context...
  oc adm policy add-scc-to-user $SCC system:serviceaccounts:$PROJECT
}

function addImagePullSecret {
  echo Adding Image Pull Secret
  oc policy add-role-to-group \
    system:image-puller system:serviceaccounts:$PROJECT \
    --namespace=project-b
}

function createWorkDir {
  echo Creating work directory...
  mkdir -p $WORK_DIR
}

function unpackAPIC {

  echo Unpacking API Connect...
  tar xzvf $INSTALL_DIR/$APIC
}

function defineRegistry {
  # Save endpoint
  export INTERNAL_REG_HOST=`oc get route docker-registry --template='{{ .spec.host }}' -n default`

  echo Docker Registry: $INTERNAL_REG_HOST
}

function dockerLogin {
  # Login
  docker login -u `oc whoami` -p `oc whoami -t` $INTERNAL_REG_HOST
}

function loadImages {
  cd images
  for i in *
  do
    echo Loading $i
    docker load --input $i
  done
  cd ..
}

# Thjis function requires the defineRegistry function
function generateYAMLs {
  mkdir -p resources
  helm template $APIC_CHART --namespace $PROJECT --name apic \
    --output-dir resources --set operator.registry=$INTERNAL_REG_HOST
}

function removeAPIC {
  oc delete --recursive --filename resources

}

function installAPIC {
  oc apply --recursive --filename resources
}


#unzipImage

#createProject
#updateSCC
addImagePullSecret

cd $WORK_DIR
#unpackAPIC
#defineRegistry
#dockerLogin
#loadImages

cd charts
#generateYAMLs
#removeAPIC
#installAPIC
