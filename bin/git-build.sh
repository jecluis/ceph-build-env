#!/bin/bash

[[ -z "$CEPH_RELEASE" ]] && \
  echo "git-build: error: requires CEPH_RELEASE" && exit 1
[[ -z "$DISTRO" ]] && \
  echo "git-build: error: requires DISTRO" && exit 1

echo "list /ceph:"
ls /ceph

echo "list /ceph/src:"
ls /ceph/src

build_name="${DISTRO}-${CEPH_RELEASE}"

src_dir="/ceph/src/${build_name}"
ccache_dir="/ceph/ccache/${build_name}"
bin_dir="/ceph/bin"

[[ ! -e "${src_dir}" ]] && \
  echo "git-build: error: unable to find source dir at '${src_dir}'" && \
  exit 1
[[ ! -e "${ccache_dir}" ]] && \
  echo "git-build: error: unable to find ccache dir at '${ccache_dir}'" && \
  exit 1
[[ ! -e "${bin_dir}" ]] && \
  echo "git-build: error: unable to find bin dir at '${bin_dir}'" && \
  exit 1

cat <<EOF
  > build-git
    >> build name:   ${build_name}
    >> src:          ${src_dir}
    >> ccache:       ${ccache_dir}
    >> bin:          ${bin_dir}

EOF

${bin_dir}/git-cmake.sh ${src_dir} ${ccache_dir} || exit 1


