# vim: ft=dockerfile
ARG DISTRO=leap-15.0
FROM ceph-build-env/base:${DISTRO}
LABEL maintainer="Joao Eduardo Luis <joao@suse.com>"

ARG CEPH_RELEASE master
RUN echo "${DISTRO} - ceph base build deps - ${CEPH_RELEASE}"

# assume branch as 'luminous' by default; let the user specify otherwise
# via a runtime --env override
#

RUN mkdir /ceph/tmp
WORKDIR /ceph/tmp

# we are setting this image for luminous
#
RUN (echo "grab install-deps.sh from github" && \
      wget https://github.com/ceph/ceph/raw/${CEPH_RELEASE}/install-deps.sh)
RUN (echo "grab ceph.spec.in from github" && \
      wget https://github.com/ceph/ceph/raw/${CEPH_RELEASE}/ceph.spec.in)
RUN /bin/bash ./install-deps.sh
# done with installing deps; remove repo
WORKDIR /ceph
RUN rm -fr /ceph/tmp
