#!/bin/bash
# chmod u+x uninstall.sh

# REQUIREMENTS
# - helm (curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 && chmod 700 get_helm.sh && ./get_helm.sh)
# - yq (wget https://github.com/mikefarah/yq/releases/download/v4.30.6/yq_linux_amd64.tar.gz -O - | tar xz && mv yq_linux_amd64 /usr/bin/yq)

# DEFINES - versions
nfsVer=4.0.17
# VARIABLE DEFINES
logFile="${HOME}/nfs/uninstall.log"
#logFile="/dev/null"
networkIPAddress=192.168.0.0
hostIPAddress=192.168.0.215

echo "[TASK] Remove nfs subdir external provisioner manifests"
kubectl delete -f /${HOME}/nfs/deployment.yaml >>${logFile} 2>&1
kubectl delete -f /${HOME}/nfs/storage-class.yaml >>${logFile} 2>&1
kubectl delete -f /${HOME}/nfs/rbac.yaml >>${logFile} 2>&1

read -p "[INPUT] Please run uninstallClient.sh on other nodes then press any key to continue... " -n1 -s
echo ""

echo "[TASK] Remove kubedata from fstab"
sed -i '/\/srv\/nfs\/kubedata/d' /etc/fstab >>${logFile} 2>&1

echo "[TASK] Remove kubedata from exports"
sed -i '/\/srv\/nfs\/kubedata/d' /etc/exports >>${logFile} 2>&1

echo "[TASK] Delete kubedata directory"
rm -r /srv/nfs/kubedata >>${logFile} 2>&1

echo "[TASK] Apply the reverted exportfs"
exportfs -rav >>${logFile} 2>&1

echo "[TASK] Uninstall nfs-kernel-server"
apt purge -qq -y --auto-remove nfs-kernel-server >>${logFile} 2>&1

echo "[TASK] Delete firewall allow all from local ip addresses"
ufw delete allow from ${networkIPAddress}/24 >>${logFile} 2>&1

echo "COMPLETE"
