ARG go_version
ARG grpc_version

FROM alpine:3.8 AS alpine-build

# TIL docker arg variables need to be redefined in each build stage
ARG grpc_version

RUN set -ex && apk --update --no-cache add \
    bash \
    make \
    cmake \
    autoconf \
    automake \
    curl \
    tar \
    libtool \
    g++ \
    git \
    libstdc++ \
    ca-certificates \
    nss

WORKDIR /tmp
COPY all/install-protobuf.sh /tmp
RUN chmod +x /tmp/install-protobuf.sh
RUN /tmp/install-protobuf.sh ${grpc_version}
RUN git clone https://github.com/googleapis/googleapis

RUN curl -sSL https://github.com/uber/prototool/releases/download/v1.3.0/prototool-$(uname -s)-$(uname -m) \
    -o /usr/local/bin/prototool && \
    chmod +x /usr/local/bin/prototool

##################################################
FROM golang:${go_version}-alpine AS go-build

ARG grpc_web_version

RUN set -ex && apk --update --no-cache add \
    curl \
    git

# Go get go-related bins
RUN go get -u google.golang.org/grpc

RUN go get -u github.com/grpc-ecosystem/grpc-gateway/protoc-gen-grpc-gateway
RUN go get -u github.com/grpc-ecosystem/grpc-gateway/protoc-gen-openapiv2
RUN go get -u github.com/golang/protobuf/protoc-gen-go

RUN go get -u github.com/gogo/protobuf/protoc-gen-gogo
RUN go get -u github.com/gogo/protobuf/protoc-gen-gogofast

RUN go get -u github.com/ckaznocha/protoc-gen-lint
RUN go get -u github.com/pseudomuto/protoc-gen-doc/cmd/protoc-gen-doc

# Add grpc-web support

RUN curl -sSL https://github.com/grpc/grpc-web/releases/download/${grpc_web_version}/protoc-gen-grpc-web-${grpc_web_version}-linux-x86_64 \
    -o /tmp/grpc_web_plugin && \
    chmod +x /tmp/grpc_web_plugin

##################################################
FROM alpine:latest AS protoc-all

RUN set -ex && apk --update --no-cache add \
    bash \
    libstdc++ \
    libc6-compat \
    ca-certificates \
    nodejs \
    nodejs-npm

# Add TypeScript support

RUN npm i -g ts-protoc-gen@0.12.0

COPY --from=alpine-build /tmp/grpc/bins/opt/grpc_* /usr/local/bin/
COPY --from=alpine-build /tmp/grpc/bins/opt/protobuf/protoc /usr/local/bin/
COPY --from=alpine-build /tmp/grpc/libs/opt/ /usr/local/lib/
COPY --from=alpine-build /tmp/googleapis/google/ /opt/include/google
COPY --from=alpine-build /usr/local/include/google/ /opt/include/google
COPY --from=alpine-build /usr/local/bin/prototool /usr/local/bin/prototool
COPY --from=go-build /go/bin/* /usr/local/bin/
COPY --from=go-build /tmp/grpc_web_plugin /usr/local/bin/grpc_web_plugin

COPY --from=go-build /go/src/github.com/grpc-ecosystem/grpc-gateway/protoc-gen-openapiv2/options/ /opt/include/protoc-gen-openapiv2/options/

ADD all/entrypoint.sh /usr/local/bin
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /defs
ENTRYPOINT [ "entrypoint.sh" ]

# protoc
FROM protoc-all AS protoc
ENTRYPOINT [ "protoc", "-I/opt/include" ]

# prototool
FROM protoc-all AS prototool
ENTRYPOINT [ "prototool" ]

# grpc-cli
FROM protoc-all as grpc-cli

ADD ./cli/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /run
ENTRYPOINT [ "/entrypoint.sh" ]

# gen-grpc-gateway
FROM protoc-all AS gen-grpc-gateway

COPY gwy/templates /templates
COPY gwy/generate_gateway.sh /usr/local/bin
RUN chmod +x /usr/local/bin/generate_gateway.sh

WORKDIR /defs
ENTRYPOINT [ "generate_gateway.sh" ]
