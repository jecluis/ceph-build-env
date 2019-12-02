#!/bin/bash

release=$1

[[ -z "$release" ]] && \
  echo "usage: $0 <release-name>" && exit 1

src_dir=/ceph/src
build_dir=/ceph/builds
ccache_dir=/ceph/ccache/$release
bin_dir=/ceph/bin

# check expected version
#
version=$($bin_dir/get-ceph-version.sh)
[[ -z "$version" ]] && \
  echo "unable to determine ceph version? abort." && exit 1
branch_name=$($bin_dir/get-ceph-branch.sh $src_dir name)
[[ -z "$branch_name" ]] && \
  echo "unable to determine branch name" && exit 1
branch_sha=$($bin_dir/get-ceph-branch.sh $src_dir sha)
[[ -z "$branch_sha" ]] && \
  echo "unable to determine branch sha" && exit 1

# setup rpmbuild environment
#

#d=$(date +%Y-%m-%dT%H:%M:%S)
#d="foo"
d=$(date +%Y-%m-%dT%H-%M-%S)
release_name="rpm-${branch_name}-${branch_sha}-${d}"
release_dir=$build_dir/$release/${release_name}
dist_dir=$build_dir/$release/dists
rpmbuild_dir=$release_dir/rpmbuild

if [[ ! -e "$release_dir" ]]; then
  mkdir $release_dir || exit 1
fi

# setup rpmbuild tree
#
sudo zypper --gpg-auto-import-keys --non-interactive \
  install rpmbuild rpmdevtools
HOME=$release_dir rpmdev-setuptree || exit 1
[[ -e "$rpmbuild_dir" ]] || exit 1
[[ -d "$rpmbuild_dir" ]] || exit 1

[[ -e "$rpmbuild_dir/SOURCES" ]] || exit 1
[[ -e "$rpmbuild_dir/SPECS" ]] || exit 1

# prepare dist file if not exists
#
[[ ! -e "$dist_dir" ]] && mkdir $dist_dir

dist_file=ceph-${version}.tar.bz2
needs_dist=true

if [[ -e "$dist_dir/$dist_file" ]]; then
  echo "using dist file found in $dist_dir/$dist_file"
  needs_dist=false
fi

if $needs_dist; then

  if [[ -e "$src_dir/$dist_file" ]]; then
    echo "found dist file in source directory"
    mv $src_dir/$dist_file $dist_dir
  else
    echo "building dist file from source"
    ( cd $src_dir && ./make-dist ) || exit 1
    [[ ! -e "$src_dir/$dist_file" ]] && \
      echo "somehow we assumed the wrong dist file name?" && exit 1
    mv $src_dir/$dist_file $dist_dir || exit 1
  fi
fi

# prepare rpmbuild
#
cp $dist_dir/$dist_file $rpmbuild_dir/SOURCES || exit 1
tar --strip-components=1 -C $rpmbuild_dir/SPECS/ --no-anchored \
  -xvjf $dist_dir/$dist_file "ceph.spec" || exit 1

[[ -e "$rpmbuild_dir/SPECS/ceph.spec" ]] || exit 1

export CCACHE_DIR=$ccache_dir
export CCACHE_BASEDIR=$rpmbuild_dir/BUILD/ceph-${version}
export CEPH_EXTRA_CMAKE_ARGS="-DWITH_CCACHE=ON" # -DWITH_TESTS=ON"
# build rpms
#
rpmbuild_args="--with=ceph_test_package"

echo "---------------------"
echo "   ceph rpm build    "
echo "---------------------"
echo "release:               ${release}"
echo "rpmbuild_dir:          ${rpmbuild_dir}"
echo "dist dir               ${dist_dir}"
echo "dist file:             ${dist_file}"
echo "version:               ${version}"
echo "---------------------"
echo "CCACHE_DIR:            ${CCACHE_DIR}"
echo "CCACHE_BASEDIR:        ${CCACHE_BASEDIR}"
echo "CEPH_EXTRA_CMAKE_ARGS: ${CEPH_EXTRA_CMAKE_ARGS}"
echo "rpmbuild args:         ${rpmbuild_args}"
echo "---------------------"

(HOME=$release_dir rpmbuild -ba $rpmbuild_args \
  $rpmbuild_dir/SPECS/ceph.spec |& \
  tee $release_dir/rpmbuild.log) || exit 1
