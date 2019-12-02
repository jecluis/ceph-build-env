#!/bin/bash

# accepts the following environment variables:
#
#   BUILD_NUM_CORES     specified the number of cores to build with
#   BUILD_DRY_RUN       performs a dry run instead
#   BUILD_WITH_PYTHON3  builds using python3 only
#


dry_run() {
  echo "> $*"
  return 0
}

src_dir=${1}
ccache_dir=${2}

[[ -z "${src_dir}" ]] && \
  echo "error: git-cmake: source dir not provided" && exit 1
[[ -z "${ccache_dir}" ]] && \
  echo "error: git-cmake: ccache dir not provided" && exit 1

[[ ! -e "${src_dir}" ]] && \
  echo "error: git-cmake: source dir does not exist" && exit 1
[[ ! -e "${ccache_dir}" ]] && \
  echo "error: git-cmake: ccache dir does not exist" && exit 1

export CCACHE_DIR="${ccache_dir}"

num_cores=${BUILD_NUM_CORES:-$(nproc)}

dry=
[[ -n "${BUILD_DRY_RUN}" ]] && dry=dry_run

cmake_ver=cmake
type cmake3 >/dev/null 2>&1 && cmake_ver=cmake3

cd ${src_dir}
echo "install possible missing dependencies"
echo "pwd: $(pwd)"
echo "ls: $(ls)"

$dry ./install-deps.sh || exit 1

echo "update submodules if needed"
$dry git submodule update --init --recursive || exit 1

if [[ ! -e "build" ]]; then
  mkdir build/
  cd build || exit 1
  $dry $cmake_ver \
  -DBOOST_J=$(nproc) \
  -DWITH_LTTNG=OFF -DWITH_BABELTRACE=OFF \
  $@ .. || exit 1
  cd ..
fi

if [[ -n "$dry" ]]; then
  echo "dry run, unable to actually build - exit"
  exit 0
fi

[[ ! -d "./build" ]] && \
  echo "error: git-build: build dir does not exist at '${src_dir}/build'" && \
  exit 1

cd ./build || exit 1

make -j $num_cores || exit 1

