# vim: ft=dockerfile
ARG CEPH_RELEASE=master
ARG DISTRO=leap-15.0

FROM ceph-build-env/base:${DISTRO}-${CEPH_RELEASE}
LABEL maintainer="Joao Eduardo Luis <joao@suse.com>"

ARG CEPH_RELEASE=master
ARG DISTRO=leap-15.0

RUN echo "${DISTRO} - ceph build - ${CEPH_RELEASE} git"

# there are the defaults we are expecting.
# the entrypoint script should not need them, but still to make it obvious.
#
ENV DISTRO=$DISTRO
ENV CEPH_SOURCE_DIR /ceph/src
ENV CEPH_RELEASE=$CEPH_RELEASE
ENV CEPH_BASE_BUILD_DIR /ceph/builds
ENV CEPH_BASE_CCACHE_DIR /ceph/ccache

ENTRYPOINT [ "/ceph/bin/git-build.sh" ]
