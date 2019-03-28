# vim: ft=dockerfile
ARG CEPH_BRANCH=master
ARG DISTRO=leap-15.0

FROM ceph-build-env/base:${RELEASE}-${CEPH_BRANCH}
LABEL maintainer="Joao Eduardo Luis <joao@suse.com>"

RUN echo "${DISTRO} - ceph build - ${CEPH_BRANCH} git"

# there are the defaults we are expecting.
# the entrypoint script should not need them, but still to make it obvious.
#
ENV CEPH_SOURCE_DIR /ceph/src
ENV CEPH_BRANCH ${CEPH_BRANCH}
ENV CEPH_BUILD_DISTRO ${DISTRO}
ENV CEPH_BASE_BUILD_DIR /ceph/builds
ENV CEPH_BASE_CCACHE_DIR /ceph/ccache

ENTRYPOINT [ "/ceph/bin/build-branch.sh" ]
