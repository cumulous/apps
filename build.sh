#!/bin/bash

set -e

ROOT_DIR="${PWD}"
BASE_IMAGE=aws-base

LOGIN=$(aws ecr get-login)
ECR=$(echo ${LOGIN} | sed 's|.*https://||')
REPO_BASE=${ECR}/${STACK_NAME}

${LOGIN}

calc_hash() {
  find "$1" -type f -exec md5sum {} \; |
    sort -k 2 |
    md5sum |
    cut -d ' ' -f1
}

tag_and_push() {
  local name="$1"
  local tag="$2"
  local repo=${REPO_BASE}/${name}

  docker tag ${name} ${repo}:${tag}
  docker push ${repo}:${tag}
}

build_image() {
  local name=$1
  local build=$2
  local repo_name=${STACK_NAME}/${name}

  cd "${ROOT_DIR}/images/${name}"

  local hash=$(calc_hash .)

  aws ecr create-repository --repository-name ${repo_name} || true
  aws ecr describe-images --repository-name ${repo_name} --image-ids imageTag="${hash}" || build=true

  if [ -z "${build}" ]; then
    false
  else
    docker build -t ${name} .

    local version=$(docker inspect -f '{{ .Config.Labels.Version }}' ${name})

    tag_and_push ${name} ${version}
    tag_and_push ${name} ${hash}
  fi
}

REBUILD=true
build_image ${BASE_IMAGE} || {
  docker pull ${REPO_BASE}/${BASE_IMAGE}
  docker tag ${REPO_BASE}/${BASE_IMAGE} ${BASE_IMAGE}
  REBUILD=
}

for app in $(ls "${ROOT_DIR}/images/apps"); do
  build_image apps/${app} ${REBUILD} || true
done
