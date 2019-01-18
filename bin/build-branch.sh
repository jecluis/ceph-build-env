#!/bin/bash

echo "----------------------------------------------------------------------"
echo "                        ENTRYPOINT                                    "
echo "----------------------------------------------------------------------"
echo " ENVIRONMENT VARIABLES                                                "
echo ""
env
echo "----------------------------------------------------------------------"


release=${CEPH_RELEASE:-luminous}
src_dir=${CEPH_SOURCE_DIR:-/ceph/src}

[[ ! -e "${src_dir}" ]] && \
  echo "source directory at '${src_dir}' does not exist; abort" && exit 1
[[ ! -d "${src_dir}" ]] && \
  echo "'${src_dir}' is not a directory; abort" && exit 1

[[ ! -e "${src_dir}/.git" ]] && \
  echo "there isn't a git repository in '${src_dir}'; abort" && exit 1

branch=${CEPH_BRANCH:-$release}

[[ -z "$branch" ]] && \
  echo "error: CEPH_BRANCH and CEPH_RELEASE not specified; abort" && exit 1

build_base_dir=${CEPH_BASE_BUILD_DIR:-/ceph/builds}
[[ ! -e "${build_base_dir}" ]] && \
  echo "builds dir at '${build_base_dir}' does not exist; abort" && exit 1
[[ ! -d "${build_base_dir}" ]] && \
  echo "'${build_base_dir}' is not a directory; abort" && exit 1

ccache_base_dir=${CEPH_BASE_CCACHE_DIR:-/ceph/ccache}
[[ ! -e "${ccache_base_dir}" ]] && \
  echo "ccache dir at '${ccache_base_dir}' does not exist; abort" && exit 1
[[ ! -d "${ccache_base_dir}" ]] && \
  echo "'${ccache_base_dir}' is not a directory; abort" && exit 1

release_build_dir=${build_base_dir}/${release}
release_ccache_dir=${ccache_base_dir}/${release}

[[ ! -e "${release_build_dir}" ]] && mkdir ${release_build_dir}

if [[ -z "$CEPH_BUILD_WITHOUT_CCACHE" ]]; then
  export CCACHE_DIR=${release_ccache_dir}
  if [[ ! -e "${release_ccache_dir}" ]]; then
    mkdir ${release_ccache_dir}
    ccache -M 20G
    echo "enabled ccache at ${release_ccache_dir}"
    echo "$(ccache -s)"
  fi
else
  echo "explicitly disabling ccache"
  unset CCACHE_DIR
  release_ccache_dir=""
fi

cd $src_dir
git checkout $branch

sha=$(git rev-parse --short HEAD)
build="${branch}-${sha}-$(date +%Y-%m-%dT%H-%M-%S)"
build_dir=${CEPH_BUILD_DIR:-${release_build_dir}/${build}}

../bin/ceph-do-cmake.sh $build_dir $src_dir

