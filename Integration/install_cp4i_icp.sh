EXEC=kubectl

PROJECT=cp4i
SCC=ibm-privileged-scc
INSTALL_DIR=/root/Integration/install/installer_files/cluster/icipcontent
APIC=IBM-API-Connect-Enterprise-for-IBM-Cloud-Integration-Platform-1.0.0.tgz
APIC_CHART=ibm-apiconnect-cip-prod-1.0.0.tgz
WORK_DIR=/root/work_cp4i
CLUSTER_DOMAIN=cloudpaks.icp

function createProject {
  echo Creating project...
  $EXEC create ns $PROJECT
}

function updatePSP {
  echo Updating PSP...
  kubectl -n $PROJECT create rolebinding pod-security-policy-rolebinding \
    --clusterrole=pod-security-policy-clusterrole --group=system:serviceaccounts:namespace
}

function addImagePullSecret {
  kubectl config set-context cloudpaks-context --namespace=$PROJECT

  kubectl create secret docker-registry myregistrykey --docker-server=$CLUSTER_DOMAIN:8500 \
    --docker-username=admin --docker-password=$ICP_PASSWORD --docker-email=patro@patro.org
}

function login {
  cloudctl login -a https://$CLUSTER_DOMAIN:8443 --skip-ssl-validation
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



createProject
updatePSP
addImagePullSecret
login

cd $WORK_DIR
#unpackAPIC
#defineRegistry
#dockerLogin
#loadImages

cd charts
#generateYAMLs
#removeAPIC
#installAPIC
