#!/bin/bash

build_dir=$1
shift 1

cat << EOF
------------------------------------------------
       this is your env for the build
------------------------------------------------
$(env | sort)
------------------------------------------------
           nprocs: $(nproc)
------------------------------------------------

EOF

BUILD_NUM_CORES=${BUILD_NUM_CORES:-$(nproc)}

bin_dir=${CEPH_BIN_DIR:-/ceph/bin}

[[ -z "${build_dir}" ]] && \
  echo "build dir not specified" && exit 1

cd ${build_dir}

ARGS=""

if [[ -n "$CCACHE_DIR" ]]; then
  with_ccache=true
  ARGS="-DWITH_CCACHE=ON"
else
  with_ccache=false
  ARGS="-DWITH_CCACHE=OFF"
fi

pybuild=${CEPH_BUILD_PYBUILD:-"3"}
case $pybuild in
  2)
    ARGS="$ARGS -DWITH_PYTHON2=ON -DWITH_PYTHON3=OFF -DMGR_PYTHON_VERSION=2"
    ;;
  3)
    ARGS="$ARGS -DWITH_PYTHON2=OFF -DWITH_PYTHON3=ON -DMGR_PYTHON_VERSION=3"
    ;;
  *)
    echo "unknown python version '$pybuild'" && exit 1
    ;;
esac

cat << EOF
preparing build
  #CORES:    ${BUILD_NUM_CORES}
  PYTHON:    v${pybuild}
  DISTRO:    ${CEPH_BUILD_DISTRO}

  BIN DIR:   ${bin_dir}
  BUILD DIR: ${build_dir}
  BRANCH:    $(${bin_dir}/git-helper.sh ${build_dir} branch get-name)
  SHA:       $(${bin_dir}/git-helper.sh ${build_dir} branch get-sha)
EOF
[[ $with_ccache ]] && \
cat << EOF
  CCACHE:    $CCACHE_DIR"
EOF
echo ""

if [[ -n "${CEPH_BUILD_DRY_RUN}" ]]; then
  echo "build dry run, exit"
  exit 0
fi

echo "install possible missing dependencies"
./install-deps.sh || exit 1

echo "preparing source repo at ${build_dir}"
git submodule update --init --recursive || exit 1

CMAKE=cmake
if type cmake3 >/dev/null 2>&1 ; then
  CMAKE=cmake3
fi

${CMAKE} \
  -DBOOST_J=$(nproc) \
  -DWITH_LTTNG=OFF -DWITH_BABELTRACE=OFF \
  $ARGS $@ . || exit 1

echo "build prepared; building."
[[ -e "$(pwd)/build" ]] || \
  echo "build dir at '$(pwd)/build' does not exist" && exit 1
cd build

make -j $BUILD_NUM_CORES
