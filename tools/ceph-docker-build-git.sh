#!/bin/bash

base_target_path=/ceph
base_host_path=/home/joao/docker
host_src_path=/home/joao/code/ceph.%release%

update_paths() {
  base_host_env_path=$(realpath ${base_host_path}/ceph-build-env 2>/dev/null)
  host_ccache_path=$(realpath ${base_host_path}/ccache 2>/dev/null)
  host_bin_path=$(realpath ${base_host_env_path}/bin 2>/dev/null)
  host_builds_path=$(realpath ${base_host_path}/builds 2>/dev/null)

  target_ccache_path=${base_target_path}/ccache
  target_bin_path=${base_target_path}/bin
  target_src_path=${base_target_path}/src
  target_builds_path=${base_target_path}/builds

  [[ -z "${base_host_env_path}" ]] || [[ -z "${host_ccache_path}" ]] || \
    [[ -z "${host_bin_path}" ]] || [[ -z "${host_builds_path}" ]] || \
    [[ -z "${target_ccache_path}" ]] || [[ -z "${target_bin_path}" ]] || \
    [[ -z "${target_src_path}" ]] || [[ -z "${target_builds_path}" ]] && \
    echo "error: some paths are unspecified or do not exist" && exit 1
}

update_paths

usage() {
  update_paths

  cat <<EOF
usage: $0 <distro> <release> <git|rpm> [options]

options:
  -h|--help                      this message
  --with-target-path PATH        with base target (container side) at PATH
                                 (default: ${base_target_path}
  --with-host-path PATH          with base host path at PATH
                                 (default: ${base_host_path})
  --with-host-ccache-path PATH   with ccache host path at PATH
                                 (default: ${host_ccache_path})
  --with-host-src-path PATH      set host source path for <release> at PATH
                                 (default: ${host_src_path})
  --with-host-builds-path PATH   set host's builds path for <release> at PATH
                                 (default: ${host_builds_path})

  --without-ccache               do not use ccache

EOF
}

[[ $# -lt 3 ]] && usage && exit 1

distro=$1
release=$2
image_type=$3
shift 3

with_ccache=true

update_paths ;

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      usage
      exit 0
      ;;
    --with-target-path)
      [[ -z "$2" ]] && >&2 echo "base target path not specified" && \
        usage && exit 1
      base_target_path=$2
      shift
      ;;
    --with-host-path)
      [[ -z "$2" ]] && >&2 echo "base host path not specified" && \
        usage && exit 1
      base_host_path=$2
      shift
      ;;
    --with-host-ccache-path)
      [[ -z "$2" ]] && >&2 echo "ccache base path not specified" && \
        usage && exit 1
      host_ccache_path=$2
      with_ccache=true
      shift
      ;;
    --with-host-src-path)
      [[ -z "$2" ]] && >&2 echo "host's source path not specified" && \
        usage && exit 1
      host_src_path=$2
      shift
      ;;
    --with-host-builds-path)
      [[ -z "$2" ]] && >&2 echo "host's builds path not specified" && \
        usage && exit 1
      host_builds_path=$2
      shift
      ;;
    --without-ccache)
      >&2 echo "compiling without ccache"
      with_ccache=false
      ;;
    *)
      >2& echo "unknown option '$1'"
      usage
      exit 1
      ;;
  esac
  shift
done

update_paths ;

actual_host_src_path=$(echo $host_src_path | \
  sed -n "s/%release%/${release}/p")

cat <<EOF

HOST PATHS:
  BASE:       ${base_host_path}
  HOST ENV:   ${base_host_env_path}
  BIN:        ${host_bin_path}
  CCACHE:     ${host_ccache_path}
  BUILDS:     ${host_builds_path}
  SOURCE:     ${host_src_path}
  ACTUAL SRC: ${actual_host_src_path}

TARGET PATHS:
  BASE:       ${base_target_path}
  BIN:        ${target_bin_path}
  CCACHE:     ${target_ccache_path}
  SOURCE:     ${target_src_path}
  BUILD:      ${target_builds_path}

BUILD:
  DISTRO:     ${distro}
  RELEASE:    ${release}
  IMAGE:      ${image_type}

EOF

actual_image="ceph-build-env/${image_type}:${distro}-${release}"

extra_args=""
if $with_ccache; then
  >&2 cat <<EOF

compiling with ccache:
  HOST:   ${host_ccache_path}
  TARGET: ${target_ccache_path}

EOF
  extra_args="-v ${host_ccache_path}:${target_ccache_path}"
else
  extra_args="--env CEPH_BUILD_WITHOUT_CCACHE=TRUE"
fi

cid=$(docker run -tid \
  -v ${actual_host_src_path}:${target_src_path} \
  -v ${host_builds_path}:${target_builds_path} \
  -v ${host_bin_path}:${target_bin_path} \
  ${extra_args} \
  ${actual_image})

echo $cid
