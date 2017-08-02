FROM aws-base

ARG VERSION=2.10.5

LABEL Version=${VERSION} \
      Revision=1.1

RUN wget -q "https://github.com/broadinstitute/picard/releases/download/${VERSION}/picard.jar"

ENTRYPOINT ["entrypoint.sh", "java -Xmx2g -jar picard.jar", ""]
