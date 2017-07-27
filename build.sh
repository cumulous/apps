#!/bin/bash

set -e

ROOT_DIR="${PWD}"

LOGIN=$(aws ecr get-login)
ECR=$(echo ${LOGIN} | sed 's|.*https://||')

$LOGIN

calc_hash() {
  find "$1" -type f -exec md5sum {} \; |
    sort -k 2 |
    md5sum |
    cut -d ' ' -f1
}

build_image () {
  local name=$1
  local repo_name=${STACK_NAME}/${name}

  cd "${ROOT_DIR}/images/${name}"

  local hash=$(calc_hash .)

  aws ecr create-repository --repository-name ${repo_name} || true
  aws ecr describe-images --repository-name ${repo_name} --image-ids imageTag="${hash}" || {
    docker build -t ${name} .

    local version=$(docker inspect -f '{{ .Config.Labels.Version }}' ${name})

    docker tag ${name}:latest ${ECR}/${repo_name}:${hash}
    docker tag ${name}:latest ${ECR}/${repo_name}:${version}
    docker push ${ECR}/${repo_name}:${hash}
    docker push ${ECR}/${repo_name}:${version}
  }

  cd "${ROOT_DIR}"
}

build_image aws-base

for app in $(ls images/apps); do
  build_image apps/${app}
done
