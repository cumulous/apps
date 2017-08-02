FROM aws-base

ARG VERSION=1.12

LABEL Version=${VERSION} \
      Revision=1.1

ENV URL="http://mccarrolllab.com/download/922/" \
    ZIP="dropseq.zip" \
    PREFIX="Drop-seq_tools"

RUN wget "${URL}" -qO "${ZIP}" && \
    unzip "${ZIP}" && \
    mv "${PREFIX}-${VERSION}"/* . && \
    rm -rf "${PREFIX}-${VERSION}" "${ZIP}"

ENTRYPOINT ["entrypoint.sh", "./"]
