#!/bin/bash

image_dir=$1

[[ -z "${image_dir}" ]] && \
  ( echo "usage: $0 <image-dir>"; exit 1 )

image_name_file=${image_dir}/__image_name__

if [[ ! -e "${image_name_file}" ]]; then
  echo "image name not found in ${image_name_file}"
  exit 1
fi

image_name=$(cat ${image_name_file})
if [[ -z "${image_name}" ]]; then
  echo "image name is empty; please check ${image_name_file}"
  exit 1
fi

echo "building '${image_dir}' with name '${image_name}'"

if [[ ! -e "bin/" ]]; then
  echo "please run this script from the build-env directory"
  exit 1
fi

docker build --tag ${image_name} -f ${image_dir}/Dockerfile .
