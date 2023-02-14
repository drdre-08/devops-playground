#!/bin/bash
# chmod u+x install.sh
# git add --chmod=+x install.sh

# DEFINES
gitUser=
gitToken=ghp_xxxxx
gitRepo=gitops

DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
logFile="${DIR}/install.log"
#logFile="/dev/null"

echo "[TASK 1] Running flux check pre install"
flux check --pre
echo -e "    \nPress ENTER to proceed with flux installation, Ctrl-C otherwise..."
read wait

export GITHUB_USER="${gitUser}"
export GITHUB_TOKEN="${gitToken}"

echo "[TASK 2] Flux bootstrap"
flux bootstrap github \
  --components-extra=image-reflector-controller,image-automation-controller \
  --owner=${gitUser} \
  --repository=${gitRepo} \
  --branch=master \
  --path=clusters/cluster0 \
  --token-auth \
  --personal=true \
  --private=true \
  --read-write-key

echo "[TASK 3] Clone flux repository"
git clone git@github.com:${gitUser}/${gitRepo}.git /${HOME}/{$gitRepo}

echo "[TASK 4] Creating manifests"
echo "         - common.yaml"
cat >>/${HOME}/{$gitRepo}/clusters/clustor0/common.yaml<<EOF
apiVersion: kustomize.toolkit.fluxcd.io/v1beta1
kind: Kustomization
metadata:
  name: common
  namespace: flux-system
spec:
  interval: 10m0s
  sourceRef:
    kind: GitRepository
    name: flux-system
  path: ./infra/common
  prune: true
  validation: client
EOF

echo "         - common/kustomization.yaml"
cat >>/${HOME}/{$gitRepo}/infra/common/kustomization.yaml<<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - sources
EOF

echo "         - sources/kustomization.yaml"
mkdir -p /${HOME}/{$gitRepo}/infra/common/sources
cat >>/${HOME}/{$gitRepo}/infra/common/sources/kustomization.yaml<<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: flux-system
resources:
  - chartmuseum.yaml
EOF

echo "         - sources/chartmuseum.yaml"
cat >>/${HOME}/{$gitRepo}/infra/common/sources/chartmuseum.yaml<<EOF
apiVersion: source.toolkit.fluxcd.io/v1beta1
kind: HelmRepository
metadata:
  name: chartmuseum
  namespace: flux-system
spec:
  interval: 30m
  url: https://helm.wso2.com
EOF

echo "         - apps.yaml"
cat >>/${HOME}/{$gitRepo}/clusters/clustor0/apps.yaml<<EOF
apiVersion: kustomize.toolkit.fluxcd.io/v1beta1
kind: Kustomization
metadata:
  name: apps
  namespace: flux-system
spec:
  interval: 10m0s
  sourceRef:
    kind: GitRepository
    name: flux-system
  path: ./infra/apps
  prune: true
  validation: client
EOF

echo "         - apps/kustomization.yaml"
mkdir -p /${HOME}/{$gitRepo}/infra/apps
cat >>/${HOME}/{$gitRepo}/infra/apps/kustomization.yaml<<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
EOF

echo "[TASK 5] Adding to git repository"
git add -A
git status
git commit -am "Initial deployment"
git push

echo "[TASK 5] Trigger flux reconcile git repository"
flux reconcile source git flux-system

echo "COMPLETE"
