#!/bin/bash

usage() {
  cat <<EOF
usage: $0 <distro> <release> <git|rpm> [options]

options:

  --workdir|-w <path>   where our build dirs are located
  --help|-h             this message
EOF
}

[[ $# -lt 3 ]] && \
  usage && exit 1

distro=$1
release=$2
image_type=$3

[[ -z "${distro}" ]] && \
  echo "distro not specified" && usage && exit 1
[[ -z "${release}" ]] && \
  echo "release not specified" && usage && exit 1
[[ -z "${image_type}" ]] && \
  echo "image type not specified" && usage && exit 1

workdir=$(pwd)

shift 3
while [[ $# -gt 0 ]]; do
  case $1 in
    --workdir|-w)
      [[ -z "${2}" ]] && \
        echo "option '$1' requires an argument" && usage && exit 1
      workdir=$(realpath $2)
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "unrecognized command '$1'"
      usage
      exit 1
      ;;
  esac
  shift
done

basedir=${workdir}/build-base
typedir=${workdir}/build-${image_type}

if [[ ! -e "${workdir}" ]]; then
  echo "workdir at '${workdir}' does not exist"
  exit 1
elif [[ ! -e "${basedir}" ]]; then
  echo "unable to find 'build-base' in workdir at '${workdir}'"
  exit 1
elif [[ ! -e "${typedir}" ]]; then
  echo "unable to find 'build-${image_type}' in workdir at '${workdir}'"
  exit 1
elif [[ ! -e "${workdir}/bin" ]]; then
  echo "unable to find 'bin/' directory in '${workdir}'"
  exit 1
fi

base_distros_dir=${basedir}/distros
base_release_dir=${basedir}/release

[[ ! -e "${base_distros_dir}" ]] && \
  echo "unable to find distros directory at '${base_distros_dir}'" && exit 1
[[ ! -e "${base_release_dir}" ]] && \
  echo "unable to find release directory at '${base_release_dir}'" && exit 1

actual_distro_dir=${base_distros_dir}/${distro}
actual_distro_dockerfile=${actual_distro_dir}/Dockerfile
actual_distro_image_name=${actual_distro_dir}/__image_name__

[[ ! -e "${actual_distro_dir}" ]] && \
  echo "unable to find distro '${distro}' in '${base_distros_dir}'" && exit 1
[[ ! -e "${actual_distro_dockerfile}" ]] && \
  echo "unable to find dockerfile for distro '${distro}'" && exit 1
[[ ! -e "${actual_distro_image_name}" ]] && \
  echo "unable to find image name for distro '${distro}'" && exit 1

base_release_dockerfile=${base_release_dir}/Dockerfile
base_release_image_name=${base_release_dir}/__image_name__

[[ ! -e "${base_release_dockerfile}" ]] && \
  echo "unable to find dockerfile for release '${release}'" && exit 1
[[ ! -e "${base_release_image_name}" ]] && \
  echo "unable to find image name for release '${release}'" && exit 1

release_type_dir=${typedir}/release
release_type_dockerfile=${release_type_dir}/Dockerfile
release_type_image_name=${release_type_dir}/__image_name__

[[ ! -e "${release_type_dir}" ]] && \
  echo "unable to find release type directory for '${image_type}'" && exit 1
[[ ! -e "${release_type_dockerfile}" ]] && \
  echo "unable to find dockerfile for image type '${image_type}'" && exit 1
[[ ! -e "${release_type_image_name}" ]] && \
  echo "unable to find image name for image type '${image_type}'" && exit 1

DISTRO=${distro}
RELEASE=${release}

distro_image_tag=$(eval "echo $(cat ${actual_distro_image_name})")
base_release_image_tag=$(eval "echo $(cat ${base_release_image_name})")
release_image_tag=$(eval "echo $(cat ${release_type_image_name})")

cat <<EOF

  DISTRO:
    IMAGE TAG:   ${distro_image_tag}
    DOCKERFILE:  ${actual_distro_dockerfile}

  BASE RELEASE:
    IMAGE TAG:   ${base_release_image_tag}
    DOCKERFILE:  ${base_release_dockerfile}

  RELEASE:
    IMAGE TAG:   ${release_image_tag}
    DOCKERFILE:  ${release_type_dockerfile}    

EOF

echo -e "\nbuilding distro image...\n"
docker build \
  --tag ${distro_image_tag} \
  --file ${actual_distro_dockerfile} \
  ${workdir} || exit 1

echo -e "\nbuilding base release image...\n"
docker build \
  --tag ${base_release_image_tag} \
  --file ${base_release_dockerfile} \
  --build-arg=DISTRO="${DISTRO}" \
  --build-arg=CEPH_RELEASE="${RELEASE}" \
  ${workdir} || exit 1

echo -e "\nbuilding release image...\n"
docker build \
  --tag ${release_image_tag} \
  --file ${release_type_dockerfile} \
  --build-arg=DISTRO="${DISTRO}" \
  --build-arg=CEPH_RELEASE="${RELEASE}" \
  ${workdir} || exit 1

