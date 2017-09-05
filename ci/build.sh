#!/bin/bash

KERNEL=$1

cd /opt/src/github.com/archzfs/archzfs

# build common packages
sudo ./build.sh common update
sudo ./build.sh common make
sudo ./build.sh common-git update
sudo ./build.sh common-git make

# build kernel
sudo ./build.sh ${KERNEL} update
sudo ./build.sh ${KERNEL} make
