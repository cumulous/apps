#!/bin/bash

set -e

ROOT_DIR="${PWD}"
BASE_IMAGE=aws-base

LOGIN=$(aws ecr get-login)
ECR=$(echo ${LOGIN} | sed 's|.*https://||')

$LOGIN

calc_hash() {
  find "$1" -type f -exec md5sum {} \; |
    sort -k 2 |
    md5sum |
    cut -d ' ' -f1
}

tag_and_push() {
  local name="$1"
  local tag="$2"
  local repo=${ECR}/${STACK_NAME}/${name}

  docker tag ${name} ${repo}:${tag}
  docker push ${repo}:${tag}
}

build_image() {
  local name=$1
  local force=$2
  local repo_name=${STACK_NAME}/${name}

  cd "${ROOT_DIR}/images/${name}"

  local hash=$(calc_hash .)
  local cached=1

  aws ecr create-repository --repository-name ${repo_name} || true
  aws ecr describe-images --repository-name ${repo_name} --image-ids imageTag="${hash}" || [ -z "${force}" ] || {
    docker build -t ${name} .

    local version=$(docker inspect -f '{{ .Config.Labels.Version }}' ${name})

    tag_and_push ${name} ${version}
    tag_and_push ${name} ${hash}

    cached=0
  }

  cd "${ROOT_DIR}"
  return ${cached}
}

REBUILD=true
build_image ${BASE_IMAGE} || {
  docker pull ${ECR}/${STACK_NAME}/${BASE_IMAGE}
  docker tag ${ECR}/${STACK_NAME}/${BASE_IMAGE} ${BASE_IMAGE}
  REBUILD=
}

for app in $(ls images/apps); do
  build_image apps/${app} ${REBUILD}
done
