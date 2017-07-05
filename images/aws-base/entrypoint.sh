#!/bin/bash

PREFIX="$1" && shift
ARGS="$@"

fifo() {
  local pipe="/data/$1/$2"
  mkdir -p "$(dirname "$pipe")"
  mkfifo "$pipe"
  echo "$pipe"
}

s3cp() {
  aws s3 cp "$@"
}

s3in() {
  while true; do
    s3cp "$1" - --quiet | cat > "$2"
    [[ "$3" == "0" ]] || break
  done &
}

s3in_range() {
  aws s3api get-object \
    --bucket "$1" --key "$2" --range bytes="$4" "$3" >/dev/null &
}

s3out() {
  s3cp - "$2" < "$1" &
  OUT_PIDS="${OUT_PIDS} $!"
}

s3sync() {
  aws s3 sync "$1" "$2" --exclude "*" --include "${3-*}" &
  trap "exit 143" INT TERM
  wait $!
}

s3down() {
  mkdir -p "$2"
  if flock 200; then
    s3sync "$@"
  fi 200>"$2/.lock"
}

s3up() {
  s3sync "$@"
}

URL_REGEX=
FIELD="[^:[:space:]]+"
URL_REGEX="${URL_REGEX}(i://${FIELD}(:0|:[0-9]+-[0-9]+)?"
URL_REGEX="${URL_REGEX}|o://${FIELD}"
URL_REGEX="${URL_REGEX}|d://${FIELD}:${FIELD}:${FIELD}"
URL_REGEX="${URL_REGEX}|u:${FIELD}:${FIELD}://${FIELD})"

urls=$(echo "${ARGS}" | grep -oE "${URL_REGEX}")

while read -r url; do
  mode=$(echo $url | cut -d : -f 1)
  [ -z $mode ] || [ $mode == "u" ] && continue

  bucket="$(echo $url | cut -d / -f 3)"
  key="$(echo $url | cut -d / -f 4- | cut -d : -f 1)"
  s3url="s3://$bucket/$key"
  context="$(echo $url | cut -d : -f 3)"
  target="$(echo $url | cut -d : -f 4)"

  case $mode in
    i|o)
      pipe="$(fifo "$bucket" "$key")"
      ARGS="${ARGS/$url/$pipe}"
      ;;
  esac

  case $mode in
    i)
      if [[ -z "$context" ]] || [[ "$context" == "0" ]]; then
        s3in "$s3url" "$pipe" "$context"
      else
        s3in_range "$bucket" "$key" "$pipe" "$context"
      fi
      # keep the pipe open by a dummy write handle
      exec 3>"$pipe" &
      ;;
    o)
      s3out "$pipe" "$s3url"
      ;;
    d)
      s3down "$s3url" "$target" "$context"
      ;;
  esac
done <<< "$urls"

${PREFIX}${ARGS%--*} &

trap "kill $!" INT TERM
wait $! && wait ${OUT_PIDS} || exit $?

while read -r url; do
  mode=$(echo $url | cut -d : -f 1)
  [[ $mode != "u" ]] && continue

  source="$(echo $url | cut -d : -f 2)"
  pattern="$(echo $url | cut -d : -f 3)"
  s3url="s3:$(echo $url | cut -d : -f 4)"

  s3up "$source" "$s3url" "$pattern"
done <<< "$urls"
