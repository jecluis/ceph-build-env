# vim: ft=dockerfile
FROM ceph-build-env/base:master
LABEL maintainer="Joao Eduardo Luis <joao@suse.com>"

RUN echo "opensuse leap 15.0 - ceph build - master git"

# there are the defaults we are expecting.
# the entrypoint script should not need them, but still to make it obvious.
#
ENV CEPH_SOURCE_DIR /ceph/src
ENV CEPH_BRANCH master
ENV CEPH_BASE_BUILD_DIR /ceph/builds
ENV CEPH_BASE_CCACHE_DIR /ceph/ccache
ENV CEPH_BUILD_PYBUILD 3

ENTRYPOINT [ "/ceph/bin/build-branch.sh" ]
