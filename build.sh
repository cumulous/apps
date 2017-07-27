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

  aws ecr create-repository --repository-name ${repo_name} || true
  docker pull ${ECR}/${repo_name} || true

  local remote_hash=$(docker inspect -f '{{ .Config.Labels.Hash }}' ${ECR}/${repo_name}) || true
  local local_hash=$(calc_hash .)

  if [ "${local_hash}" != "${remote_hash}" ]; then
    docker build --label Hash="${local_hash}" -t ${name} .

    local version=$(docker inspect -f '{{ .Config.Labels.Version }}' ${name})
    local repo_tag=${ECR}/${repo_name}:${version}

    docker tag ${name}:latest ${repo_tag}
    docker push ${repo_tag}
  fi

  cd "${ROOT_DIR}"
}

build_image aws-base

for app in $(ls images/apps); do
  build_image apps/${app}
done
