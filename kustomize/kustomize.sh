#!/bin/bash
set -e
cd "$(dirname ${0})"
cat <&0 > ./resources/all.yml

COMMENTS=$(awk '/^#.*$/&&!/^# Source:/ {print $0}' ./resources/all.yml)

echo -n "
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
configMapGenerator:
- name: test-kust-meta-info
  options:
    disableNameSuffixHash: true
  envs:
  - deploy.properties
" > kustomization.yml

for DIR in $(find . -mindepth 1 -type d -printf '%f\n')
do
  echo "${DIR}:" >> kustomization.yml
  for KUST_FILE in  $(ls ${DIR}/*.yaml ${DIR}/*.yml ${DIR}/*.json 2>/dev/null || : )
  do
    echo "- ${KUST_FILE}" >> kustomization.yml
  done
done
  
oc kustomize .
echo '---'
echo "$COMMENTS"
set +e