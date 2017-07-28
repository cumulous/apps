FROM alpine

LABEL Version=latest \
      Revision=1.1

WORKDIR /usr/local/bin

RUN apk add --no-cache bash openssl python py-pip && \
    pip install awscli && \
    apk del --purge py-pip

COPY entrypoint.sh .
