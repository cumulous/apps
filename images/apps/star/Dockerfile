FROM aws-base

ARG VERSION=2.5.3a

LABEL Version=${VERSION}

ENV REPO="https://github.com/alexdobin/STAR/archive"

RUN wget -q "${REPO}/${VERSION}.zip" && \
    unzip "${VERSION}.zip" && \
    mv "STAR-${VERSION}/bin/Linux_x86_64_static/STAR" . && \
    rm -rf *${VERSION}*

USER ${USER}

ENTRYPOINT ["entrypoint.sh", "STAR", ""]