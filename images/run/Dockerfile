# vim: ft=dockerfile
ARG DISTRO=leap-42.3
ARG CEPH_RELEASE=master

FROM ceph-build-env/base:${DISTRO}-${CEPH_RELEASE}
LABEL maintainer="Joao Eduardo Luis <joao@suse.com>"

RUN echo "opensuse ${DISTRO} - ceph build - dev luminous"

ENV CEPH_SOURCE_DIR /ceph/src
ENV CEPH_BRANCH luminous
ENV CEPH_BASE_BUILD_DIR /ceph/builds
ENV CEPH_BASE_CCACHE_DIR /ceph/ccache

WORKDIR /ceph

RUN sudo zypper install -y zsh tmux
RUN sudo chsh -s $(which zsh) ceph-build

#CMD $(which zsh)

CMD /ceph/bin/entrypoint-interactive.sh

