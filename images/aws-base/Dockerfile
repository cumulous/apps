FROM debian

LABEL Version=latest \
      Revision=1.3

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      openjdk-8-jre-headless \
      python \
      python-pip \
      wget \
      unzip \
    && \
    pip install \
      setuptools \
    && \
    pip install \
      awscli \
    && \
    apt-get remove -y \
      python-pip \
    && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* && \
    adduser --system user

WORKDIR /usr/local/bin

COPY entrypoint.sh .
