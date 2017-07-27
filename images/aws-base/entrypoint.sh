#!/bin/bash

PREFIX="$1" && shift
ARGS="$@"

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

URL_REGEX='[^[]*(\[/([^]]*)\]:([dio]))[^[]*'
matches=$(echo "${ARGS}" | sed -rn "s|${URL_REGEX}|\1;\2;\3\n|gp")

while read -r match; do

  IFS=';' read arg path mode <<< "${match}"

  case ${mode} in
    i|o)
      pipe="$(fifo "${path}")"
      ARGS="${ARGS/"${arg}"/"${pipe}"}"
      ;;
  esac

  s3url="s3://${DATA_BUCKET}/${path}"

  case $mode in
    i)
      s3in "${s3url}" "${pipe}"
      exec 3>"${pipe}" &
      ;;
    o)
      s3out "${pipe}" "${s3url}"
      ;;
    d)
      s3down "${s3url}" "${DATA_PATH}/${path}"
      ;;
  esac
done <<< "${matches}"

${PREFIX}${ARGS%--*} &

trap "kill $!" INT TERM
wait $! && wait ${OUT_PIDS} || exit $?
