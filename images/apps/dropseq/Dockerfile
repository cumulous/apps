FROM aws-base

ARG VERSION=1.12

LABEL Version=${VERSION}

ENV URL="http://mccarrolllab.com/download/922/" \
    ZIP="dropseq.zip" \
    PREFIX="Drop-seq_tools"

RUN apk add --no-cache openjdk8-jre-base && \
    wget "${URL}" -qO "${ZIP}" && \
    unzip "${ZIP}" && \
    mv "${PREFIX}-${VERSION}"/* . && \
    rm -rf "${PREFIX}-${VERSION}" "${ZIP}"

USER ${USER}

ENTRYPOINT ["entrypoint.sh", "./"]