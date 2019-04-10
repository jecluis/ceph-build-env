#!/bin/bash

echo "----------------------------------------------------------------------"
echo "                      BUILD BRANCH ENTRY                              "
echo "----------------------------------------------------------------------"
echo " ENVIRONMENT VARIABLES                                                "
echo ""
env | sort
echo "----------------------------------------------------------------------"

branch=${CEPH_BRANCH}
[[ -z "${branch}" ]] && \
  echo -e "CEPH_BRANCH not defined.\nThe container should do it.\nAbort." \
  && exit 1

src_dir=$(realpath ${CEPH_SOURCE_DIR:-/ceph/src})
bin_dir=$(realpath ${CEPH_BIN_DIR:-/ceph/bin})
build_distro=${CEPH_BUILD_DISTRO:-leap-15.0}
build_base_dir=$(realpath ${CEPH_BASE_BUILD_DIR:-/ceph/builds})
ccache_base_dir=$(realpath ${CEPH_BASE_CCACHE_DIR:-/ceph/ccache})

[[ -z "${src_dir}" ]] && \
  echo "source directory is empty" && exit 1
[[ -z "${bin_dir}" ]] && \
  echo "bin directory is empty" && exit 1
[[ -z "${build_distro}" ]] && \
  echo "build distro not specified" && exit 1
[[ -z "${build_base_dir}" ]] && \
  echo "build base directory not specified" && exit 1
[[ -z "${ccache_base_dir}" ]] && \
  echo "base ccache directory not specified" && exit 1

# validate src dir path
#
[[ ! -e "${src_dir}" ]] && \
  echo "source directory at '${src_dir}' does not exist; abort" && exit 1
[[ ! -d "${src_dir}" ]] && \
  echo "'${src_dir}' is not a directory; abort" && exit 1

[[ ! -e "${src_dir}/.git" ]] && \
  echo "there isn't a git repository in '${src_dir}'; abort" && exit 1

src_git_path=$(${bin_dir}/git-helper.sh ${src_dir} get-git-path 2>/dev/null)
[[ $? -ne 0 ]] && \
  echo "error obtaining git path for source dir '${src_dir}'" && exit 1

[[ -z "${src_git_path}" ]] && \
  echo "could not obtain git path from source repo at ${src_dir}" && exit 1

# obtain release's tag and branch name
#
release=$(${bin_dir}/git-helper.sh ${src_dir} get-tag 2>/dev/null)
[[ $? -ne 0 ]] && \
  echo "unable to obtain git tag for source dir at '${src_dir}'" && \
  exit 1

cur_git_branch=$(${bin_dir}/git-helper.sh ${src_dir} \
  branch get-name 2>/dev/null)
[[ -z "${cur_git_branch}" ]] && \
  echo "no current branch checked out at ${src_dir}; abort." && exit 1
branch=${CEPH_BRANCH:-${cur_git_branch}}

src_git_sha=$(${bin_dir}/git-helper.sh ${src_dir} \
  branch get-sha ${branch} 2>/dev/null)
[[ $? -ne 0 ]] && \
  echo "unable to obtain source git's sha from '${src_dir}'" && \
  exit 1

# validate build dir path
#
[[ ! -e "${build_base_dir}" ]] && \
  echo "builds dir at '${build_base_dir}' does not exist; abort" && exit 1
[[ ! -d "${build_base_dir}" ]] && \
  echo "'${build_base_dir}' is not a directory; abort" && exit 1

# check if build distro's build dir is present, and create it if not
#
build_distro_dir=${build_base_dir}/${build_distro}
[[ ! -e "${build_distro_dir}" ]] && \
  echo "creating build distro dir at '${build_distro_dir}'" && \
  mkdir -p ${build_distro_dir}

# validate ccache path
#
[[ ! -e "${ccache_base_dir}" ]] && \
  echo "ccache dir at '${ccache_base_dir}' does not exist; abort" && exit 1
[[ ! -d "${ccache_base_dir}" ]] && \
  echo "'${ccache_base_dir}' is not a directory; abort" && exit 1

# create a ccache dir per tagged release, for each build distro
#
actual_ccache_dir=${ccache_base_dir}/${build_distro}/${release}

# clone src repo so we can modify it and stuff
#
actual_build_base_dir=${build_base_dir}/${build_distro}/${release}
[[ ! -e "${actual_build_base_dir}" ]] && \
  mkdir ${actual_build_base_dir} && \
  echo "created build base directory at '${actual_build_base_dir}'"

git_attempt_update=false
target_build_base_dir=${actual_build_base_dir}/${src_git_sha}
if [[ -e "${target_build_base_dir}" ]]; then
  if [[ -e "${target_build_base_dir}/.git" ]]; then
    echo "build dir at '${target_build_base_dir}' already a git repo"
    git_attempt_update=true
  fi
fi

if [[ -z "$CEPH_BUILD_WITHOUT_CCACHE" ]]; then
  export CCACHE_DIR=${actual_ccache_dir}
  export CCACHE_BASEDIR=${target_build_base_dir}
  if [[ ! -e "${actual_ccache_dir}" ]]; then
    mkdir -p ${actual_ccache_dir}
    ccache -M 20G
    echo "enabled ccache at ${actual_ccache_dir}"
    echo "$(ccache -s)"
  fi
else
  echo "explicitly disabling ccache"
  unset CCACHE_DIR
  unset CCACHE_BASEDIR
  actual_ccache_dir=""
fi

if $git_attempt_update; then
  ${bin_dir}/git-helper.sh ${target_build_base_dir} do-update || exit 1
  ${bin_dir}/git-helper.sh ${target_build_base_dir} do-pull || exit 1

else
  ${bin_dir}/git-helper.sh ${src_dir} do-clone ${target_build_base_dir} || \
    exit 1
  ${bin_dir}/git-helper.sh ${target_build_base_dir} do-checkout ${branch} || \
    exit 1
fi

${bin_dir}/ceph-do-cmake.sh ${target_build_base_dir}

