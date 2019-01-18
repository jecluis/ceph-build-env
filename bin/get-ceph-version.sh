#!/bin/bash

cd /ceph/src
git describe --match "v*" | sed 's/^v//'
