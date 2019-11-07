#!/bin/sh

# Environment variables
# CLIENT_OS - OS for oc and openshift-install. One of linux, mac, or windows.
# CLUSTER_DIR - local directory used to store installer artificats
# PULL_SECRET - pull secret used to obtain the release payload (i.e. from try.openshift.com)
# PAYLOAD_HOST - hostname for the OpenShift 4 payload (ex: quay.io)
# PAYLOAD_IMAGE - Name of the image

if [ $# -ne 1 ]; then
  echo "Need release version, e.g. 4.0.0-0.ci-2019-04-15-011801"
  exit 1
fi

version=$1
os=${CLIENT_OS:-"linux"}
clusterDir=${CLUSTER_DIR:-"$HOME/Code/openshift/clusters/dev-4"}
pullSecret=${PULL_SECRET:-"$HOME/Code/openshift/clusters/secrets/pull-secret.json"}
host=${PAYLOAD_HOST:-"registry.svc.ci.openshift.org"}
image=${PAYLOAD_IMAGE:-"ocp/release"}


rm -rf /tmp/openshift-release
mkdir /tmp/openshift-release
pushd /tmp/openshift-release

echo "Extracting release $version"

oc adm release extract --tools --to /tmp/openshift-release -a $pullSecret "$host/$image:$version"

mkdir -p /tmp/openshift-release/oc
tar -xzf "openshift-client-$os-$version.tar.gz" -C /tmp/openshift-release/oc
cp /tmp/openshift-release/oc/oc $HOME/bin

mkdir -p /tmp/openshift-release/openshift-install
tar -xzf "openshift-install-$os-$version.tar.gz" -C /tmp/openshift-release/openshift-install
cp /tmp/openshift-release/openshift-install/openshift-install $HOME/bin

echo "Destroying previous cluster at $clusterDir"

openshift-install --dir $clusterDir destroy cluster

rm -rf $clusterDir
mkdir $clusterDir
export KUBECONFIG=$clusterDir/auth/kubeconfig
pushd $clusterDir

echo "Creating new cluster at $version"

echo "============ PULL SECRET ============"
echo " "
cat $pullSecret
echo " "
echo "===================================="

openshift-install --dir $clusterDir create cluster

popd

popd
