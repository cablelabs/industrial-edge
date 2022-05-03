#!/bin/sh

exportOpenShiftRegistry ()
{
  REG_HOST=$(oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}')

  if [ "$REG_HOST." == "." ]; then
    echo -n "Set the DefaultRoute to true ..."
    oc patch configs.imageregistry.operator.openshift.io/cluster --patch '{"spec":{"defaultRoute":true}}' --type=merge
    echo "done"
  else
    echo "Default route [$REG_HOST] already set."
  fi
}

podmanLogin () 
{
  export OCP_REG_HOST=$(oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}')
  echo -n "Login in to [$OCP_REG_HOST] using podman ..."
  podman login -u kubeadmin -p $(oc whoami -t) --tls-verify=false $OCP_REG_HOST  > /dev/null 2>&1
  echo "done"
}

openShiftLogin()
{
  OCP_SERVER=$(oc project default | awk '{print $7}' | sed "s/\"\./\"/g" | sed "s/\"//g" 2> /dev/null ) 
  echo -n "Login in to OpenShift ..."
  oc login --token=$(oc whoami -t) --server=${OCP_SERVER}
  echo  "done"

  if [ $? -gt 0 ]; then
    echo "Could not login to OpenShift"
    exit
  fi
}

boostrapImages()
{
  REG_HOST=$(oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}')
  LINE_IMAGE_EXISTS=$(oc image info ${REG_HOST}/manuela-stormshift-line-dashboard/line-dashboard:0.3.1 --insecure -a $XDG_RUNTIME_DIR/config.json | grep Digest | awk '{print $2}' 2> /dev/null)
  if [ "$LINE_IMAGE_EXISTS." == "." ]; then
    echo -n "Boostrapping Manuela image [line-dashboard] ..."
    oc image mirror quay.io/hybridcloudpatterns/iot-frontend:0.3.1 ${REG_HOST}/manuela-stormshift-line-dashboard/line-dashboard:0.3.1 --insecure=true -a $XDG_RUNTIME_DIR/containers/auth.json
    echo "done"
  else
    echo "Line Dashboard image exists [$LINE_IMAGE_EXISTS]"
  fi

  MACHINE_IMAGE_EXISTS=$(oc image info ${REG_HOST}/manuela-stormshift-machine-sensor/machine-sensor:0.3.1 --insecure -a $XDG_RUNTIME_DIR/config.json | grep Digest | awk '{print $2}' 2> /dev/null)
  if [ "$MACHINE_IMAGE_EXISTS." == "." ]; then
    echo -n "Boostrapping Manuela image [machine-sensor] ..."
    oc image mirror quay.io/hybridcloudpatterns/iot-software-sensor:0.3.1 ${REG_HOST}/manuela-stormshift-machine-sensor/machine-sensor:0.3.1 --insecure=true -a $XDG_RUNTIME_DIR/containers/auth.json
    echo "done"
  else
    echo "Machine Sensor image exists [$MACHINE_IMAGE_EXISTS]"
  fi

  MESSAGING_IMAGE_EXISTS=$(oc image info ${REG_HOST}/manuela-stormshift-messaging/messaging:0.3.2 --insecure -a $XDG_RUNTIME_DIR/config.json | grep Digest | awk '{print $2}' 2> /dev/null)
  if [ "$MESSAGING_IMAGE_EXISTS." == "." ]; then
    echo -n "Boostrapping Manuela image [messaging] ..."
    oc image mirror quay.io/hybridcloudpatterns/iot-consumer:0.3.2 ${REG_HOST}/manuela-stormshift-messaging/messaging:0.3.2 --insecure=true -a $XDG_RUNTIME_DIR/containers/auth.json
    echo "done"
  else
    echo "Messaging image exists [$MESSAGING_IMAGE_EXISTS]"
  fi

  ANOMALY_IMAGE_EXISTS=$(oc image info ${REG_HOST}/manuela-stormshift-messaging/iot-anomaly-detection:0.3.2 --insecure -a $XDG_RUNTIME_DIR/config.json | grep Digest | awk '{print $2}' 2> /dev/null)
  if [ "$ANOMALY_IMAGE_EXISTS." == "." ]; then
    echo -n "Boostrapping Manuela image [iot-anomaly-detection] ..."
    oc image mirror quay.io/hybridcloudpatterns/iot-anomaly-detection:0.3.2 ${REG_HOST}/manuela-stormshift-messaging/iot-anomaly-detection:0.3.2 --insecure=true -a $XDG_RUNTIME_DIR/containers/auth.json
    echo "done"
  else
    echo "Messaging image exists [$ANOMALY_IMAGE_EXISTS]"
  fi

}

while getopts l:s:m:q: flag
do
    case "${flag}" in
        l) linedashboard=${OPTARG};;
        s) mashinesensor=${OPTARG};;
        m) messaging=${OPTARG};;
	q) qaccount=${OPTARG};;
    esac
done
echo "linedashboard: $linedashboard";
echo "machinesensor: $machinesensor";
echo "messaging: $messaging";
echo "qaccount: $qaccount";
exportOpenShiftRegistry
podmanLogin 
openShiftLogin 
boostrapImages
