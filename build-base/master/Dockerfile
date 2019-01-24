# vim: ft=dockerfile
FROM ceph-build-env/base:leap-15.0
LABEL maintainer="Joao Eduardo Luis <joao@suse.com>"

RUN echo "opensuse leap 15.0 - ceph base build deps - master"

# assume branch as 'luminous' by default; let the user specify otherwise
# via a runtime --env override
#
ENV CEPH_RELEASE master

RUN mkdir /ceph/tmp
WORKDIR /ceph/tmp

# we are setting this image for luminous
#
RUN (echo "grab install-deps.sh from github" && \
      wget https://github.com/ceph/ceph/raw/master/install-deps.sh)
RUN (echo "grab ceph.spec.in from github" && \
      wget https://github.com/ceph/ceph/raw/master/ceph.spec.in)
RUN /bin/bash ./install-deps.sh
# done with installing deps; remove repo
WORKDIR /ceph
RUN rm -fr /ceph/tmp
