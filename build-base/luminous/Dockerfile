# vim: ft=dockerfile
FROM ceph-build-base
LABEL maintainer="Joao Eduardo Luis <joao@suse.com>"

RUN echo "opensuse leap 42.3 - ceph base build deps - luminous"

# assume branch as 'luminous' by default; let the user specify otherwise
# via a runtime --env override
#
ENV CEPH_RELEASE luminous

RUN mkdir /ceph/tmp
WORKDIR /ceph/tmp

# we are setting this image for luminous
#
RUN (echo "clone luminous" && \
      git clone https://github.com/ceph/ceph.git ceph.luminous)
WORKDIR /ceph/tmp/ceph.luminous
RUN (echo "install luminous dependencies" && \
      git checkout origin/luminous -b luminous)

RUN /bin/bash ./install-deps.sh
# done with installing deps; remove repo
RUN rm -fr /ceph/tmp/ceph.luminous

