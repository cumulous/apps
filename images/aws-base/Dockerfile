FROM alpine

LABEL Version=1.0

ENV USER=user

WORKDIR /usr/local/bin

RUN apk add --no-cache bash openssl python py-pip && \
    pip install awscli && \
    apk del --purge py-pip && \
    adduser -S ${USER}

COPY entrypoint.sh .
