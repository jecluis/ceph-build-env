# vim: ft=dockerfile
FROM opensuse/leap:15.0
LABEL maintainer="Joao Eduardo Luis <joao@suse.com>"

RUN echo "opensuse leap 15.0 - ceph build base image"

# install system dependencies
#
RUN zypper --gpg-auto-import-keys refresh
RUN zypper -n dup
RUN zypper -n install git sudo wget ccache

# prepare build user
#
RUN groupadd wheel
RUN useradd -d /ceph -c 'ceph build' -u 1000 -U -G wheel ceph-build
RUN mkdir /ceph && chown ceph-build:ceph-build /ceph

ADD sudoers.docker /etc/sudoers
RUN chmod a-w /etc/sudoers
RUN chown root:root /etc/sudoers

USER ceph-build:ceph-build

RUN echo "prepare build directory tree"
RUN echo "  source directory at /ceph/src" && mkdir /ceph/src
RUN echo "  build directory at /ceph/builds" && mkdir /ceph/builds
RUN echo "  ccache directory at /ceph/ccache" && mkdir /ceph/ccache
RUN echo "  bin directory at /ceph/bin" && mkdir /ceph/bin

VOLUME ["/ceph/src", "/ceph/builds", "/ceph/ccache", "/ceph/bin"]
