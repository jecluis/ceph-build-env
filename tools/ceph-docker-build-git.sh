#!/bin/bash

[[ $# -lt 2 ]] && \
  echo "usage: $0 <release> <image-name> [--without-ccache]" && \
  exit 1

release=$1
image=$2

with_ccache=true
if [[ -n "$3" ]] && [[ "$3" == "--without-ccache" ]]; then
  with_ccache=false
fi

ARGS=""
if $with_ccache; then
  >&2 echo "with ccache"
  ARGS="-v /home/joao/docker/ccache-all:/ceph/ccache"
else
  ARGS="--env CEPH_BUILD_WITHOUT_CCACHE=TRUE"
fi

cid=$(docker run -tid \
  -v /home/joao/code/ceph.$release:/ceph/src \
  -v /home/joao/code/builds:/ceph/builds \
  -v /home/joao/docker/ceph-build-env/bin:/ceph/bin \
  $ARGS \
  $image)

echo $cid
