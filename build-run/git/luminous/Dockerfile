# vim: ft=dockerfile
FROM ceph-build-env/dev:luminous
LABEL maintainer="Joao Eduardo Luis <joao@suse.com>"

RUN echo "opensuse leap 42.3 - ceph build - dev luminous"

ENV CEPH_SOURCE_DIR /ceph/src
ENV CEPH_BRANCH luminous
ENV CEPH_BASE_BUILD_DIR /ceph/builds
ENV CEPH_BASE_CCACHE_DIR /ceph/ccache

CMD /bin/bash

