#!/bin/bash

export PREFIX="$1" && shift
export ARGS="$@"
export DATA_PATH="${DATA_PATH:-/data}"
export DATA_BUCKET
export LOG_DEST

USER=user

run() {
  fifo() {
    local pipe="/tmp/$1"

    mkdir -p "$(dirname "${pipe}")"
    mkfifo "${pipe}"
    echo "${pipe}"
  }

  s3cp() {
    aws s3 cp "$@"
  }

  s3in() {
    local path="$1"
    local pipe="$2"

    while true; do
      s3cp "s3://${DATA_BUCKET}/${path}" - --quiet | cat >"${pipe}"
    done &
  }

  s3out() {
    local pipe="$1"
    local path="$2"

    s3cp - "s3://${DATA_BUCKET}/${path}" < "${pipe}" &
    OUT_PID=$!
    OUT_PIDS="${OUT_PIDS} ${OUT_PID}"
  }

  s3sync() {
    local dir="$1"
    local dest="$2"
    local filter="$3"

    aws s3 sync "s3://${DATA_BUCKET}/${dir}" "${dest}" --exclude "*" --include "${filter}" &
    trap "exit 143" INT TERM
    wait $!
  }

  s3down() {
    local path="$1"
    local dir=$(dirname "${path}")
    local filter=$(basename  "${path}")

    if [[ ${path} == */ ]]; then
      dir="${path}"
      filter="*"
    fi

    local dest="${DATA_PATH}/${dir}"
    mkdir -p "${dest}"
    if flock 200; then
      s3sync "${dir}" "${dest}" "${filter}"
    fi 200>"${dest}/.lock"
  }

  local regex='[^[]*(\[([dio]):/([^]]*)\])[^[]*'
  local matches=$(echo "${ARGS}" | sed -rn "s|${regex}|\1;\2;\3\n|gp")

  while read -r match; do

    IFS=';' read arg mode path <<< "${match}"

    case ${mode} in
      i|o)
        pipe="$(fifo "${path}")"
        ARGS="${ARGS/"${arg}"/"${pipe}"}"
        ;;
      d)
        ARGS="${ARGS/"${arg}"/"${DATA_PATH}/${path}"}"
        ;;
    esac

    case $mode in
      i)
        s3in "${path}" "${pipe}"
        ;;
      o)
        s3out "${pipe}" "${path}"
        ;;
      d)
        s3down "${path}"
        ;;
    esac
  done <<< "${matches}"

  local log="$(fifo "${LOG_DEST}")"
  s3out "${log}" "${LOG_DEST}"

  ${PREFIX}${ARGS%--*} &>"${log}" &

  trap "kill $!" INT TERM
  wait $! && wait ${OUT_PIDS} || \
    { code=$? && wait ${OUT_PID} ; exit ${code} ; }
}

adduser -S ${USER}
mkdir -p ${DATA_PATH}
chown ${USER} ${DATA_PATH}

export -f run
exec su ${USER} -s /bin/bash -c run
