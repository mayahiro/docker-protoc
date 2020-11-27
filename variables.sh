#!/bin/bash -e

DOCKER_REPO=${DOCKER_REPO}
GRPC_VERSION=${GRPC_VERSION:-1.21}
NAMESPACE=${NAMESPACE:-mayahiro}
BUILD_VERSION=${BUILD_VERSION:-1}
CONTAINER=${DOCKER_REPO}${NAMESPACE}
LATEST=${1:false}
BUILDS=("protoc-all" "protoc" "prototool" "grpc-cli" "gen-grpc-gateway")
