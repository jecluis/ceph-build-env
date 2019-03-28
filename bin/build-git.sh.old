#!/bin/bash

echo "----------------------------------------------------------------------"
echo "                      BUILD BRANCH ENTRY                              "
echo "----------------------------------------------------------------------"
echo " ENVIRONMENT VARIABLES                                                "
echo ""
env
echo "----------------------------------------------------------------------"

release=${CEPH_RELEASE}
[[ -z "${release}" ]] && \
  echo -e "CEPH_RELEASE not defined.\nThe container should do it.\nAbort." \
  && exit 1

src_dir=${CEPH_SOURCE_DIR:-/ceph/src}
bin_dir=${CEPH_BIN_DIR:-/ceph/bin}

[[ ! -e "${src_dir}" ]] && \
  echo "source directory at '${src_dir}' does not exist; abort" && exit 1
[[ ! -d "${src_dir}" ]] && \
  echo "'${src_dir}' is not a directory; abort" && exit 1

[[ ! -e "${src_dir}/.git" ]] && \
  echo "there isn't a git repository in '${src_dir}'; abort" && exit 1

cur_git_branch=$(${bin_dir}/get-ceph-branch.sh ${src_dir} name)
[[ -z "${cur_git_branch}" ]] && \
  echo "no current branch checked out at ${src_dir}; abort." && exit 1

branch=${CEPH_BRANCH:-${cur_git_branch}}

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
build="git-${branch}-${sha}-$(date +%Y-%m-%dT%H-%M-%S)"
build_dir=${CEPH_BUILD_DIR:-${release_build_dir}/${build}}

${bin_dir}/ceph-do-cmake.sh $build_dir $src_dir

