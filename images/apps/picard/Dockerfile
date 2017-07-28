FROM aws-base

ARG VERSION=2.10.5

LABEL Version=${VERSION}

ENV REPO="https://github.com/broadinstitute/picard/releases/download"

RUN apk add --no-cache openjdk8-jre-base && \
    wget -q "${REPO}/${VERSION}/picard.jar"

ENTRYPOINT ["entrypoint.sh", "java -jar picard.jar", ""]
