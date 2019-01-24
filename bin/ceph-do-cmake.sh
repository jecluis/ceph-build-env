#!/bin/bash

build_dir=$1
shift 1
src_dir=$1
shift 1

echo "this be your env for the build"
env
echo "----------"
echo "nprocs: $(nproc)"
echo "----------"

BUILD_NUM_CORES=${BUILD_NUM_CORES:-2}

[[ -z "$build_dir" ]] && \
  echo "build dir not specified" && exit 1

[[ -e "$build_dir" ]] && \
  echo "build dir already exists at '$build_dir'" && exit 1

[[ -z "$src_dir" ]] && \
  echo "source dir not specified" && exit 1
[[ ! -e "$src_dir" ]] && \
  echo "source dir does not exist at '$src_dir'" && exit 1

cd $src_dir

echo "install possible missing dependencies"
./install-deps.sh || exit 1

echo "preparing source repo at ${src_dir}"
git submodule update --init --recursive || exit 1

ARGS=""

if [[ -n "$CCACHE_DIR" ]]; then
	with_ccache=true
	ARGS="-DWITH_CCACHE=ON"
else
	with_ccache=false
	ARGS="-DWITH_CCACHE=OFF"
fi

echo "preparing build"
echo "  BUILD DIR: $build_dir"
echo "  BRANCH:    $(git rev-parse --abbrev-ref HEAD)"
echo "  SHA:       $(git rev-parse --short HEAD)"
[[ $with_ccache ]] && \
  echo "  CCACHE:    $CCACHE_DIR"
echo ""
mkdir $build_dir || exit 1
cd $build_dir

if [[ -n "${CEPH_BUILD_DRY_RUN}" ]]; then
  echo "build dry run, exit"
  exit 0
fi

pybuild=${CEPH_BUILD_PYBUILD:-"2"}
if [[ "$pybuild" == "3" ]]; then
  ARGS="$ARGS -DWITH_PYTHON2=OFF -DWITH_PYTHON3=ON -DMGR_PYTHON_VERSION=3"
fi

CMAKE=cmake
if type cmake3 >/dev/null 2>&1 ; then
  CMAKE=cmake3
fi

${CMAKE} \
  -DBOOST_J=$(nproc) \
  -DWITH_LTTNG=OFF -DWITH_BABELTRACE=OFF \
  $ARGS $@ $src_dir || exit 1

echo "build prepared; building."
make -j $BUILD_NUM_CORES
