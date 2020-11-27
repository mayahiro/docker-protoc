#!/bin/bash -e

DOCKER_REPO=${DOCKER_REPO}
NAMESPACE=${NAMESPACE:-namely}
GRPC_VERSION=${GRPC_VERSION:-1.21}
BUILD_VERSION=${BUILD_VERSION:-1}
CONTAINER=${DOCKER_REPO}${NAMESPACE}
LATEST=${1:false}
BUILDS=("protoc-all" "protoc" "prototool" "grpc-cli" "gen-grpc-gateway")
