#!/bin/bash -e

if [ -z $1 ]; then
    echo "You must specify a grpc version."
    exit 1
fi

curl -sSL https://github.com/gflags/gflags/archive/v2.2.1.tar.gz -o gflags.tar.gz && tar -xzvf gflags.tar.gz
cd gflags-2.2.1/
cmake .
make
make install

cd /tmp

git clone -b v$1.x --recursive -j8 https://github.com/grpc/grpc
cd /tmp/grpc
make
make install

git submodule update --init

cp /tmp/grpc/bins/opt/protobuf/protoc /usr/local/bin/

cd /tmp/grpc/third_party/protobuf
make
make install

cd /tmp/grpc/third_party/protobuf
./autogen.sh
cd /tmp/grpc
make grpc_cli
