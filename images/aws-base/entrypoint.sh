#!/bin/bash

set -e

export PREFIX="$1" && shift
export ARGS="$@"
export DATA_PATH="${DATA_PATH:-/data}"
export DATA_BUCKET

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
    while true; do
      s3cp "$1" - --quiet | cat > "$2"
      break
    done &
  }

  s3out() {
    s3cp - "$2" < "$1" &
    OUT_PIDS="${OUT_PIDS} $!"
  }

  s3sync() {
    aws s3 sync "$1" "$2" &
    trap "exit 143" INT TERM
    wait $!
  }

  s3down() {
    mkdir -p "$2"
    if flock 200; then
      s3sync "$@"
    fi 200>"$2/.lock"
  }

  local regex='[^[]*(\[/([^]]*)\]:([dio]))[^[]*'
  local matches=$(echo "${args}" | sed -rn "s|${regex}|\1;\2;\3\n|gp")

  while read -r match; do

    IFS=';' read arg path mode <<< "${match}"

    case ${mode} in
      i|o)
        pipe="$(fifo "${path}")"
        args="${args/"${arg}"/"'${pipe}'"}"
        ;;
      d)
        args="${args/"${arg}"/"'${data_path}/${path}'"}"
        ;;
    esac

    s3url="s3://${data_bucket}/${path}"

    case $mode in
      i)
        s3in "${s3url}" "${pipe}"
        exec 3>"${pipe}" &
        ;;
      o)
        s3out "${pipe}" "${s3url}"
        ;;
      d)
        s3down "${s3url}" "${data_path}/${path}"
        ;;
    esac
  done <<< "${matches}"

  ${PREFIX}${ARGS%--*} &

  trap "kill $!" INT TERM
  wait $! && wait ${OUT_PIDS} || exit $?
}

adduser -S ${USER}
mkdir -p ${DATA_PATH}
chown ${USER} ${DATA_PATH}

export -f run
exec su ${USER} -s /bin/bash -c run
