FROM aws-base

ARG VERSION=2.5.3a

LABEL Version=${VERSION}

RUN wget -q "https://github.com/alexdobin/STAR/archive/${VERSION}.zip" && \
    unzip "${VERSION}.zip" && \
    mv "STAR-${VERSION}/bin/Linux_x86_64_static/STAR" . && \
    rm -rf *${VERSION}*

ENTRYPOINT ["entrypoint.sh", "STAR", ""]
