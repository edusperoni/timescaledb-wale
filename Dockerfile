# Need to use an Alpine image that has python 3.5, since WAL-E doesn't
# work well with newer Pythons
FROM golang:1.17-alpine AS builder

ENV WALG_VERSION=v1.1

ENV _build_deps="wget cmake git build-base bash"

RUN set -ex  \
     && apk add --no-cache $_build_deps \
     && git clone https://github.com/wal-g/wal-g/  $GOPATH/src/wal-g \
     && cd $GOPATH/src/wal-g/ \
     && git checkout $WALG_VERSION \
     && make install_and_build_pg \
     && install main/pg/wal-g / \
     && /wal-g --help

FROM alpine:latest

COPY --from=builder /wal-g /usr/local/bin/

# Add run dependencies in its own layer
RUN apk add --no-cache --virtual .run-deps python3 lzo curl pv postgresql-client

COPY requirements.txt /
RUN apk add --no-cache --virtual .build-deps gcc libc-dev lzo-dev python3-dev py3-pip && \
    python3 -m pip install --no-cache-dir -r requirements.txt && \
    apk del .build-deps

COPY src/wale-rest.py .
COPY run.sh /

CMD [ "/run.sh" ]
