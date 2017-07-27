#!/bin/bash

set -e

ROOT_DIR="${PWD}"

LOGIN=$(aws ecr get-login)
ECR=$(echo ${LOGIN} | sed 's|.*https://||')

$LOGIN

build_image () {
  local name=$1
  local repo_name=${STACK_NAME}/${name}

  cd "${ROOT_DIR}/images/${name}"

  aws ecr create-repository --repository-name ${repo_name} | true
  docker pull ${ECR}/${repo_name} | true
  docker build -t ${name} .

  local version=$(docker image inspect ${name} -f '{{ .Config.Labels.Version }}')
  local repo_tag=${ECR}/${repo_name}:${version}

  docker tag ${name}:latest ${repo_tag}
  docker push ${repo_tag}

  cd "${ROOT_DIR}"
}

build_image aws-base

for app in $(ls images/apps); do
  build_image apps/${app}
done
